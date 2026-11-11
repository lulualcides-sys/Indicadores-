"""Extracao independente da deteccao de ranges do Auto Range Detector.

Implementacao exploratoria em Python para pesquisa de estrategias, sem ordens.
Usa apenas OHLC conhecidos ate cada fechamento. Nao e porta identica ao Pine v6;
percentrank e inicializacao historica podem diferir em detalhes.

Dependencias: numpy, pandas
"""
from __future__ import annotations
from dataclasses import dataclass
import math
import numpy as np
import pandas as pd


@dataclass(frozen=True)
class RangeConfig:
    base_length: int = 20
    scan_scaling: int = 3   # 1, 2, 3 janelas: base, 2x, 3x
    boundary_basis: str = "percentile"  # percentile, extremes, body
    boundary_percentile: float = 90.0
    atr_length: int = 200
    compression_percentile: float = 40.0
    calibration_lookback: int = 500
    min_rotation: float = 0.18
    touch_basis: str = "wick"  # wick, close
    min_touches: int = 2
    touch_tolerance_atr: float = 0.10
    max_drift: float = 0.45
    min_containment: float = 0.70

    def __post_init__(self) -> None:
        if self.base_length < 8 or self.scan_scaling not in (1, 2, 3):
            raise ValueError("base_length >= 8 e scan_scaling em 1, 2, 3")
        if self.boundary_basis not in ("percentile", "extremes", "body"):
            raise ValueError("boundary_basis invalido")
        if self.touch_basis not in ("wick", "close"):
            raise ValueError("touch_basis invalido")
        if not (0 < self.boundary_percentile <= 100):
            raise ValueError("boundary_percentile fora da faixa")
        if self.atr_length < 2 or self.calibration_lookback < 2:
            raise ValueError("historicos devem ter pelo menos 2 barras")


def wilder_atr(high: np.ndarray, low: np.ndarray,
               close: np.ndarray, length: int) -> np.ndarray:
    """ATR Wilder, com seed SMA; nenhum acesso a candles futuros."""
    n = len(close)
    tr = np.empty(n, dtype=float)
    if n == 0:
        return tr
    tr[0] = high[0] - low[0]
    if n > 1:
        tr[1:] = np.maximum.reduce((high[1:] - low[1:],
                                    np.abs(high[1:] - close[:-1]),
                                    np.abs(low[1:] - close[:-1])))
    out = np.full(n, np.nan)
    if n >= length:
        out[length - 1] = tr[:length].mean()
        for i in range(length, n):
            out[i] = (out[i-1] * (length - 1) + tr[i]) / length
    return out


def extract_range_features(ohlc: pd.DataFrame,
                           config: RangeConfig = RangeConfig()) -> pd.DataFrame:
    """Uma linha por candle, no fechamento: candidatos a range, nao trades.

    Resultados da ultima linha nao devem ser usados antes do fechamento.
    Se varias janelas qualificarem, seleciona a maior, como no indicador.
    """
    cols = ("open", "high", "low", "close")
    missing = [c for c in cols if c not in ohlc.columns]
    if missing:
        raise ValueError(f"Colunas OHLC ausentes: {missing}")
    if ohlc[list(cols)].isna().any().any():
        raise ValueError("OHLC nao pode conter NaN")
    if not ohlc.index.is_monotonic_increasing:
        raise ValueError("OHLC deve estar em ordem cronologica crescente")
    arr = {col: ohlc[col].to_numpy(dtype=float) for col in cols}
    op, hi, lo, cl = (arr[c] for c in cols)
    if np.any(hi < np.maximum.reduce((op, cl, lo))) or np.any(lo > np.minimum(op, cl)):
        raise ValueError("OHLC inconsistente: high/low nao contem abertura e fechamento")
    n = len(ohlc)
    atr = wilder_atr(hi, lo, cl, config.atr_length)
    data = {"atr": atr, "range_qualified": np.zeros(n, dtype=bool),
            "scan_length": np.zeros(n, dtype=int),
            "range_top": np.full(n, np.nan), "range_bottom": np.full(n, np.nan),
            "compression_rank": np.full(n, np.nan),
            "rotation_crossings": np.full(n, np.nan),
            "top_touches": np.full(n, np.nan),
            "bottom_touches": np.full(n, np.nan),
            "drift_ratio": np.full(n, np.nan),
            "containment": np.full(n, np.nan)}
    # Preencher com 99 antes de ha ATR valido aproxima a serie "compression"
    # do Pine. A diferenca exata de bootstrap/percentrank nao foi auditada.
    length_results: dict[int, dict[str, np.ndarray]] = {}
    for multiplier in range(1, config.scan_scaling + 1):
        length = config.base_length * multiplier
        compression = np.full(n, 99.0)
        qualifies = np.zeros(n, dtype=bool)
        top_series = np.full(n, np.nan)
        bottom_series = np.full(n, np.nan)
        rank_series = np.full(n, np.nan)
        rotations = np.full(n, np.nan)
        hits_top = np.full(n, np.nan)
        hits_bottom = np.full(n, np.nan)
        drifts = np.full(n, np.nan)
        containments = np.full(n, np.nan)
        x = np.arange(length, dtype=float)
        xc = x - x.mean()
        x_var = float(xc @ xc)
        for i in range(length - 1, n):
            s = slice(i - length + 1, i + 1)
            hw, lw, cw = hi[s], lo[s], cl[s]
            if config.boundary_basis == "percentile":
                top = float(np.quantile(hw, config.boundary_percentile / 100, method="linear"))
                bottom = float(np.quantile(lw, 1 - config.boundary_percentile / 100, method="linear"))
            elif config.boundary_basis == "extremes":
                top, bottom = float(hw.max()), float(lw.min())
            else:
                top = float(np.maximum(op[s], cl[s]).max())
                bottom = float(np.minimum(op[s], cl[s]).min())
            top_series[i] = top
            bottom_series[i] = bottom
            height = top - bottom
            atr_i = atr[i]
            if np.isfinite(atr_i) and atr_i > 0 and height > 0:
                compression[i] = height / (atr_i * math.sqrt(length))
            span = max(1, min(config.calibration_lookback, i - config.atr_length))
            # Percentual de scores <= atual, dentro de janela retrospectiva.
            left = max(0, i - span + 1)
            rank = 100.0 * float(np.mean(compression[left:i+1] <= compression[i]))
            rank_series[i] = rank
            if not (np.isfinite(atr_i) and atr_i > 0 and height > 0 and i > length + 5):
                continue
            midpoint = (top + bottom) / 2
            # Pine faz close[i] vs close[i+1], incluindo a barra imediatamente
            # anterior a janela de estudo. O fechamento dessa barra ja e conhecido.
            if i >= length:
                cross_closes = cl[i-length:i+1]
                crossings = int(np.count_nonzero((cross_closes[1:] > midpoint) != (cross_closes[:-1] > midpoint)))
            else:
                crossings = 0
            tol = config.touch_tolerance_atr * atr_i
            if config.touch_basis == "wick":
                ht = int(np.count_nonzero(hw >= top - tol))
                hb = int(np.count_nonzero(lw <= bottom + tol))
            else:
                ht = int(np.count_nonzero(cw >= top - tol))
                hb = int(np.count_nonzero(cw <= bottom + tol))
            contained = float(np.mean((cw <= top) & (cw >= bottom)))
            slope = float(xc @ cw / x_var)
            drift = abs(slope) * length / height
            rotations[i] = crossings
            hits_top[i] = ht
            hits_bottom[i] = hb
            drifts[i] = drift
            containments[i] = contained
            qualifies[i] = (
                rank <= config.compression_percentile
                and crossings >= max(3, math.floor(config.min_rotation * length + 0.5))
                and ht >= config.min_touches and hb >= config.min_touches
                and drift <= config.max_drift
                and contained >= config.min_containment
            )
        length_results[length] = {
            "qualified": qualifies, "top": top_series, "bottom": bottom_series,
            "rank": rank_series, "rotation": rotations, "hit_top": hits_top,
            "hit_bottom": hits_bottom, "drift": drifts, "containment": containments,
        }
    # Menor primeiro, maior sobrepoe: janela mais longa qualificada prevalece.
    for length, res in length_results.items():
        mask = res["qualified"]
        data["range_qualified"][mask] = True
        data["scan_length"][mask] = length
        for dst, src in (("range_top", "top"), ("range_bottom", "bottom"),
                         ("compression_rank", "rank"),
                         ("rotation_crossings", "rotation"),
                         ("top_touches", "hit_top"),
                         ("bottom_touches", "hit_bottom"),
                         ("drift_ratio", "drift"),
                         ("containment", "containment")):
            data[dst][mask] = res[src][mask]
    features = pd.DataFrame(data, index=ohlc.index)
    features["equilibrium"] = (features.range_top + features.range_bottom) / 2
    features["quartile_25"] = features.range_bottom + (features.range_top - features.range_bottom) * 0.25
    features["quartile_75"] = features.range_bottom + (features.range_top - features.range_bottom) * 0.75
    return features