"""Independent, closed-candle research extraction of Market Structure Dynamics & OB.

Only OHLCV columns are required; no packages, trading/account access, or future candles.
Not a translation guaranteed to match Pine Script bar-for-bar. No entries/exits or P&L.
The original source is stored separately, unchanged, under 01_originais/.
"""
from __future__ import annotations

from dataclasses import dataclass
from math import isfinite, sqrt
from typing import Literal, Optional, Sequence


@dataclass(frozen=True)
class Candle:
    open: float
    high: float
    low: float
    close: float
    volume: Optional[float] = None

    def __post_init__(self):
        if self.low > self.high or min(self.open, self.close) < self.low or max(self.open, self.close) > self.high:
            raise ValueError('OHLC inconsistente')
        if not all(map(isfinite, [self.open, self.high, self.low, self.close])):
            raise ValueError('OHLC não finito')


@dataclass(frozen=True)
class BreakEvent:
    index: int
    direction: Literal['bull', 'bear']
    pivot_index: int
    pivot_price: float
    zscore: float
    volume_percent_rank: Optional[float]
    quality_heuristic: Optional[float]
    block_index: Optional[int]
    block_top: Optional[float]
    block_bottom: Optional[float]


@dataclass(frozen=True)
class BlockEvent:
    created_at: int
    source_index: int
    direction: Literal['bull', 'bear']
    top: float
    bottom: float
    quality_heuristic: Optional[float]
    first_touch_index: Optional[int] = None
    invalidated_at: Optional[int] = None


def zscore_of_latest_diff(closes: Sequence[float], length: int = 50) -> Optional[float]:
    """Latest close-to-close change vs last `length` changes; biased population stdev.

    `None` for insufficient observations / zero dispersion, avoiding 0/0.
    """
    if len(closes) < length + 1:
        return None
    diffs = [closes[i] - closes[i - 1] for i in range(len(closes) - length, len(closes))]
    mu = sum(diffs) / length
    sd = sqrt(sum((x - mu) ** 2 for x in diffs) / length)
    return (diffs[-1] - mu) / sd if sd > 1e-12 else None


def volume_percent_rank(volumes: Sequence[Optional[float]], length: int = 100) -> Optional[float]:
    """Approximation of ta.percentrank(volume,length), including the current bar."""
    if len(volumes) < length:
        return None
    window = volumes[-length:]
    if any(v is None or not isfinite(v) for v in window):
        return None
    last = window[-1]
    return 100.0 * sum(v <= last for v in window) / length


def pivot_just_confirmed(bars: Sequence[Candle], lookback: int, kind: Literal['high', 'low']) -> Optional[tuple[int, float]]:
    """Strict local extremum only confirmed after `lookback` right-side bars.

    Pivot-tie selection differs from Pine in some equal-high/equal-low cases.
    """
    if lookback < 1:
        raise ValueError('lookback >= 1')
    n = len(bars)
    if n < 2 * lookback + 1:
        return None
    k = n - 1 - lookback
    vals = [b.high if kind == 'high' else b.low for b in bars[k - lookback:k + lookback + 1]]
    centre = vals[lookback]
    if kind == 'high' and all(centre > v for j, v in enumerate(vals) if j != lookback):
        return (k, centre)
    if kind == 'low' and all(centre < v for j, v in enumerate(vals) if j != lookback):
        return (k, centre)
    return None


def intervals_overlap(lo1: float, hi1: float, lo2: float, hi2: float) -> bool:
    """Detect containment as well as partial overlap; closed intervals."""
    return max(lo1, lo2) <= min(hi1, hi2)


def candidate_opposite_candle(bars: Sequence[Candle], index: int, direction: Literal['bull', 'bear'], max_back: int = 10) -> Optional[int]:
    """Find last opposite-colour candle strictly BEFORE breakout; never bar 0 fallback."""
    for offset in range(1, min(max_back, index) + 1):
        bar = bars[index - offset]
        if direction == 'bull' and bar.close < bar.open:
            return index - offset
        if direction == 'bear' and bar.close > bar.open:
            return index - offset
    return None


def _quality(zscore: Optional[float], percentile: Optional[float]) -> Optional[float]:
    # Faithfully preserve the original arithmetic, NOT the original probability claim.
    if zscore is None or percentile is None:
        return None
    return min(100.0, abs(zscore) * 20.0 + percentile * 0.5)


def extract_market_structure(
    bars: Sequence[Candle],
    *,
    lookback: int = 7,
    z_window: int = 50,
    volume_window: int = 100,
    break_z: float = 0.5,
    block_search: int = 10,
    avoid_overlap: bool = True,
) -> tuple[list[BreakEvent], list[BlockEvent]]:
    """Research BOS / blocks: reads only each completed bar and its past.

    Touch = any intersection with the block at a *later* bar.
    Invalidation = a *later* close through the distal edge; not conflated with touch.
    First-touch and invalidation are descriptive, never trading orders.
    """
    if lookback < 1 or z_window < 2 or volume_window < 2 or block_search < 1:
        raise ValueError('janelas inválidas')
    if break_z < 0:
        raise ValueError('break_z deve ser não negativo')
    events: list[BreakEvent] = []
    blocks: list[BlockEvent] = []
    last_high = None
    last_low = None
    closes: list[float] = []
    volumes: list[Optional[float]] = []

    for index, current in enumerate(bars):
        closes.append(current.close)
        volumes.append(current.volume)

        # Lifecycle of PREVIOUS blocks: creation candle is never eligible.
        for j, b in enumerate(blocks):
            if b.invalidated_at is not None:
                continue
            touch = b.first_touch_index
            if touch is None and current.low <= b.top and current.high >= b.bottom:
                touch = index
            invalid = b.invalidated_at
            if (b.direction == 'bull' and current.close < b.bottom) or (b.direction == 'bear' and current.close > b.top):
                invalid = index
            if touch != b.first_touch_index or invalid != b.invalidated_at:
                blocks[j] = BlockEvent(b.created_at, b.source_index, b.direction, b.top, b.bottom,
                                       b.quality_heuristic, touch, invalid)

        high_pivot = pivot_just_confirmed(bars[:index + 1], lookback, 'high')
        low_pivot = pivot_just_confirmed(bars[:index + 1], lookback, 'low')
        if high_pivot:
            last_high = high_pivot
        if low_pivot:
            last_low = low_pivot

        z = zscore_of_latest_diff(closes, z_window)
        if z is None or index == 0:
            continue
        pr = volume_percent_rank(volumes, volume_window)
        q = _quality(z, pr)
        dirn = None
        pivot = None
        if last_high and current.close > last_high[1] and bars[index - 1].close <= last_high[1] and z > break_z:
            dirn, pivot = 'bull', last_high
            last_high = None
        elif last_low and current.close < last_low[1] and bars[index - 1].close >= last_low[1] and z < -break_z:
            dirn, pivot = 'bear', last_low
            last_low = None
        if dirn is None:
            continue

        candidate = candidate_opposite_candle(bars, index, dirn, block_search)
        block_index = candidate
        top, bottom = (bars[candidate].high, bars[candidate].low) if candidate is not None else (None, None)
        if candidate is not None:
            if avoid_overlap and any(b.invalidated_at is None and intervals_overlap(bottom, top, b.bottom, b.top) for b in blocks):
                block_index, top, bottom = None, None, None
            else:
                blocks.append(BlockEvent(index, candidate, dirn, top, bottom, q))
        events.append(BreakEvent(index, dirn, pivot[0], pivot[1], z, pr, q, block_index, top, bottom))

    return events, blocks