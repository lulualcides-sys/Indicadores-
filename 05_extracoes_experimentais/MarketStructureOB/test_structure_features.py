import unittest
from structure_features import (Candle, candidate_opposite_candle, extract_market_structure,
                               intervals_overlap, pivot_just_confirmed, volume_percent_rank, zscore_of_latest_diff)


def bar(close, high=None, low=None, open_=None, vol=100.0):
    op = close if open_ is None else open_
    hi = max(close, op) if high is None else high
    lo = min(close, op) if low is None else low
    return Candle(op, hi, lo, close, vol)


class Tests(unittest.TestCase):
    def test_no_lookahead_pivot(self):
        bars = [bar(2, high=3), bar(5, high=8), bar(3, high=4)]
        self.assertIsNone(pivot_just_confirmed(bars[:2], 1, 'high'))
        self.assertEqual(pivot_just_confirmed(bars, 1, 'high'), (1, 8))

    def test_pivot_ties_ignored(self):
        bars = [bar(2, high=4), bar(4, high=4), bar(2, high=3)]
        self.assertIsNone(pivot_just_confirmed(bars, 1, 'high'))

    def test_containment_overlap(self):
        self.assertTrue(intervals_overlap(1, 10, 3, 4))
        self.assertTrue(intervals_overlap(3, 4, 1, 10))
        self.assertFalse(intervals_overlap(1, 2, 3, 4))

    def test_no_opposite_candle(self):
        bars = [bar(1.1, open_=1), bar(2.1, open_=2), bar(3.1, open_=3)]
        self.assertIsNone(candidate_opposite_candle(bars, 2, 'bull'))

    def test_rolling_math(self):
        self.assertIsNone(zscore_of_latest_diff([1, 2, 3, 4], 3))
        self.assertEqual(volume_percent_rank([1, 3, 2, 4], 4), 100)
        self.assertIsNone(volume_percent_rank([None, 3, 2, 4], 4))

    def test_event_prefix_stability(self):
        # Alternates around a growing baseline, with one strong bullish breakout.
        bars = [bar(100 + .02 * i + (0.9 if i % 6 == 0 else -0.4),
                    high=101 + .03 * i + (0.7 if i % 6 == 0 else 0),
                    low=99 + .01 * i - (0.5 if i % 6 == 3 else 0),
                    open_=100 + .02 * i, vol=100 + i) for i in range(130)]
        full, _ = extract_market_structure(bars, lookback=2, z_window=5, volume_window=5)
        short, _ = extract_market_structure(bars[:90], lookback=2, z_window=5, volume_window=5)
        self.assertEqual(short, [e for e in full if e.index < 90])

    def test_closed_bar_bos_and_block(self):
        bars = [bar(10), bar(12, high=13), bar(10, high=11, open_=11),
                bar(9, high=11), bar(10, high=11), bar(14, high=15, low=10, open_=11)]
        events, blocks = extract_market_structure(bars, lookback=1, z_window=2, volume_window=2, break_z=0.1)
        buys = [e for e in events if e.direction == 'bull']
        self.assertTrue(buys)
        self.assertEqual(buys[-1].index, 5)
        self.assertEqual(buys[-1].pivot_price, 13)
        self.assertTrue(buys[-1].quality_heuristic is not None)
        self.assertTrue(all(b.created_at <= 5 for b in blocks))

    def test_zero_volatility(self):
        self.assertIsNone(zscore_of_latest_diff([10, 10, 10, 10], length=3))

    def test_invalid_ohlc_rejected(self):
        with self.assertRaises(ValueError):
            Candle(2, 1, 1, 2)

    def test_no_future_data_for_first_n_bars(self):
        bars = [bar(10), bar(12, high=13), bar(10, high=11, open_=11),
                bar(9, high=11), bar(10, high=11), bar(14, high=15, low=10, open_=11),
                bar(12, high=15, low=11)]
        a, _ = extract_market_structure(bars[:6], lookback=1, z_window=2, volume_window=2)
        b, _ = extract_market_structure(bars, lookback=1, z_window=2, volume_window=2)
        self.assertEqual(a, [x for x in b if x.index < 6])


if __name__ == '__main__':
    unittest.main()