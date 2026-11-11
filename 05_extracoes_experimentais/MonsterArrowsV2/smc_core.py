"""Primitivas SMC experimentais, independentes de MT5/TradingView.

NÃO É um robô, nem uma estratégia validada. Não contém execução de ordens.
Tudo opera com candles OHLC fechados, fornecidos em ordem temporal crescente.
A confirmação de pivôs ocorre apenas após `right` candles adicionais.
"""
from __future__ import annotations

from dataclasses import dataclass
from math import isfinite
from typing import Iterable, Literal, Sequence


@dataclass(frozen=True)
class Candle:
    open: float
    high: float
    low: float
    close: float

    def __post_init__(self) -> None:
        values = (self.open, self.high, self.low, self.close)
        if not all(isfinite(v) for v in values):
            raise ValueError("OHLC deve conter números finitos")
        if self.low > self.high or not (self.low <= self.open <= self.high) or not (self.low <= self.close <= self.high):
            raise ValueError("OHLC inconsistente")


@dataclass(frozen=True)
class Pivot:
    kind: Literal['high', 'low']
    price: float
    index: int
    confirmed_at: int


@dataclass(frozen=True)
class FVG:
    direction: Literal['bull', 'bear']
    bottom: float
    top: float
    start_index: int
    confirmed_at: int  # candle de criação do FVG (terceiro candle), após seu fechamento

    @property
    def gap(self) -> float:
        return self.top - self.bottom


def confirmed_pivots(candles: Sequence[Candle], *, left: int = 30, right: int = 2) -> list[Pivot]:
    """Detecta pivôs SEM antecipá-los: evento só é conhecido em index+right.

    Critério conservador para empates: o extremo central deve ser estritamente
    maior/menor que TODOS os candles da janela (evita ambiguidades).
    Esta é uma extração nova, NÃO uma reprodução exata de ta.pivothigh/low.
    """
    if left < 1 or right < 1:
        raise ValueError("left e right devem ser >= 1")
    out: list[Pivot] = []
    for center in range(left, len(candles) - right):
        neighbors = [candles[j] for j in range(center-left, center+right+1) if j != center]
        c = candles[center]
        if all(c.high > x.high for x in neighbors):
            out.append(Pivot('high', c.high, center, center + right))
        if all(c.low < x.low for x in neighbors):
            out.append(Pivot('low', c.low, center, center + right))
    return sorted(out, key=lambda p: (p.confirmed_at, p.index, p.kind))


def liquidity_sweep(candle: Candle, previous_level: float, *, direction: Literal['bull', 'bear'],
                    tick_size: float = 0.01, min_break_ticks: float = 0) -> bool:
    """Sweep exige ultrapassar nível pré-existente E fechar de volta do outro lado.

    Bull: low < suporte e close > suporte. Bear: high > resistência e close < resistência.
    Observação: nível deve já estar CONFIRMADO antes do candle testado.
    """
    if tick_size <= 0 or min_break_ticks < 0:
        raise ValueError("tick_size > 0 e min_break_ticks >= 0 são obrigatórios")
    tolerance = min_break_ticks * tick_size
    if direction == 'bull':
        return candle.low < previous_level - tolerance and candle.close > previous_level
    if direction == 'bear':
        return candle.high > previous_level + tolerance and candle.close < previous_level
    raise ValueError('direction inválida')


def detect_fvgs(candles: Sequence[Candle], *, tick_size: float = 0.01,
                min_gap_ticks: float = 0) -> list[FVG]:
    """FVG clássico de 3 candles; conhecido no fechamento do terceiro.

    Bull: high[i-2] < low[i]. Bear: low[i-2] > high[i].
    É propositalmente independente de 'deslocamento', contexto de tendência e mitigação.
    """
    if tick_size <= 0 or min_gap_ticks < 0:
        raise ValueError('tick_size > 0 e min_gap_ticks >= 0 são obrigatórios')
    out: list[FVG] = []
    floor = min_gap_ticks * tick_size
    for i in range(2, len(candles)):
        old, new = candles[i-2], candles[i]
        if new.low - old.high > floor:
            out.append(FVG('bull', old.high, new.low, i-2, i))
        if old.low - new.high > floor:
            out.append(FVG('bear', new.high, old.low, i-2, i))
    return out


def fvg_untouched_until(fvg: FVG, candles: Sequence[Candle], end_index: int) -> bool:
    """'Untouched': nenhuma vela posterior à formação toca a ZONA até end_index.

    Isso é mais estrito do que 'não mitigado totalmente'. O teste é inclusivo;
    end_index pode ser o índice do pivô ou do sinal (definir previamente).
    """
    if not (fvg.confirmed_at <= end_index < len(candles)):
        raise ValueError('intervalo inválido')
    for c in candles[fvg.confirmed_at + 1:end_index + 1]:
        if fvg.direction == 'bull' and c.low <= fvg.top:
            return False
        if fvg.direction == 'bear' and c.high >= fvg.bottom:
            return False
    return True


def most_recent_fvg(fvgs: Iterable[FVG], *, direction: Literal['bull', 'bear'],
                    signal_index: int, max_age: int = 30) -> FVG | None:
    """Apenas FVGs que JÁ EXISTIAM até o índice do sinal."""
    if max_age < 0:
        raise ValueError('max_age inválido')
    valid = [f for f in fvgs if f.direction == direction
             and f.confirmed_at <= signal_index
             and signal_index - f.confirmed_at <= max_age]
    return max(valid, key=lambda f: f.confirmed_at, default=None)


def wilder_atr(candles: Sequence[Candle], period: int = 14) -> list[float | None]:
    """ATR de Wilder alinhado ao fechamento de cada candle; sem dados futuros.

    Primeiro TR = high-low; seed ATR = média dos primeiros `period` TRs.
    Para ATR *diário*, fornecer candles D1 confirmados; não M1/M5.
    """
    if period < 1:
        raise ValueError('period >= 1 é obrigatório')
    out: list[float | None] = [None] * len(candles)
    tr: list[float] = []
    prev_close: float | None = None
    for candle in candles:
        tr.append(max(candle.high - candle.low,
                      abs(candle.high - prev_close) if prev_close is not None else 0,
                      abs(candle.low - prev_close) if prev_close is not None else 0))
        prev_close = candle.close
    for i in range(period - 1, len(candles)):
        if i == period-1:
            out[i] = sum(tr[:period]) / period
        else:
            assert out[i-1] is not None
            out[i] = (out[i-1] * (period - 1) + tr[i]) / period
    return out


def fib_retracement(start: float, end: float, ratio: float = 0.618) -> float:
    """Nível entre dois extremos, start + (end-start)*ratio; sem previsão de preço."""
    if not 0 <= ratio <= 1:
        raise ValueError('ratio em [0,1]')
    return start + (end-start) * ratio