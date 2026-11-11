import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'extracao_python'))
from smc_core import (Candle, confirmed_pivots, liquidity_sweep, detect_fvgs,
                      fvg_untouched_until, most_recent_fvg, wilder_atr, fib_retracement)

class SMCCoreTests(unittest.TestCase):
    def test_pivot_requires_future_confirmation(self):
        bars = [Candle(5,6,4,5), Candle(5,7,3,6), Candle(6,10,5,8),
                Candle(8,9,6,7), Candle(7,8,5,7)]
        pivots = confirmed_pivots(bars, left=2, right=2)
        highs = [p for p in pivots if p.kind == 'high']
        self.assertEqual(len(highs), 1)
        self.assertEqual((highs[0].index, highs[0].confirmed_at), (2, 4))
        self.assertFalse(any(p.confirmed_at >= 4 for p in confirmed_pivots(bars[:4], left=2, right=2)))

    def test_sweep_needs_reclaim(self):
        self.assertTrue(liquidity_sweep(Candle(100,102,98,101), 99, direction='bull'))
        self.assertFalse(liquidity_sweep(Candle(100,102,98,98.5), 99, direction='bull'))
        self.assertTrue(liquidity_sweep(Candle(100,103,99,100), 102, direction='bear'))
        self.assertFalse(liquidity_sweep(Candle(100,103,99,102.5), 102, direction='bear'))

    def test_fvg_zone_and_timing(self):
        bars = [Candle(9,10,8,9), Candle(10,12,9,11), Candle(13,15,12,14),
                Candle(14,15,13,14), Candle(14,14,10,11)]
        fvgs = detect_fvgs(bars)
        bull = [f for f in fvgs if f.direction == 'bull' and f.confirmed_at == 2][0]
        self.assertEqual((bull.bottom, bull.top), (10,12))
        self.assertTrue(fvg_untouched_until(bull, bars, 3))
        self.assertFalse(fvg_untouched_until(bull, bars, 4))
        self.assertIsNone(most_recent_fvg(fvgs, direction='bull', signal_index=1))
        self.assertEqual(most_recent_fvg(fvgs, direction='bull', signal_index=2), bull)
        self.assertEqual(most_recent_fvg(fvgs, direction='bull', signal_index=3).confirmed_at, 3)

    def test_atr_wilder(self):
        bars = [Candle(10,12,9,11), Candle(11,13,10,12), Candle(12,14,11,13)]
        atr = wilder_atr(bars, period=2)
        self.assertEqual(atr, [None, 3.0, 3.0])

    def test_fibonacci(self):
        self.assertAlmostEqual(fib_retracement(100, 200), 161.8)

    def test_validation(self):
        with self.assertRaises(ValueError):
            Candle(10, 9, 11, 10)
        with self.assertRaises(ValueError):
            confirmed_pivots([], left=0, right=2)
        with self.assertRaises(ValueError):
            wilder_atr([], period=0)

if __name__ == '__main__':
    unittest.main()