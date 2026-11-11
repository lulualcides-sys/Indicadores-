"""Testes deterministas offline; nao sao backtests de rentabilidade."""
import unittest
import numpy as np
import pandas as pd
from range_features import RangeConfig, extract_range_features, wilder_atr


def sample_data(n=160, trend=False):
    t = np.arange(n)
    close = 100 + 0.7*np.sin(t*1.1) + (0.02*t if trend else 0)
    opened = close - 0.09*np.cos(t)
    high = np.maximum(opened, close) + 0.16
    low = np.minimum(opened, close) - 0.16
    return pd.DataFrame({"open": opened, "high": high, "low": low, "close": close})


class RangeFeatureTests(unittest.TestCase):
    def setUp(self):
        self.config = RangeConfig(base_length=10, atr_length=14,
                                  calibration_lookback=40)

    def test_no_future_data_leakage(self):
        original = sample_data(110)
        extended = sample_data(160)
        first = extract_range_features(original, self.config)
        second = extract_range_features(extended, self.config).iloc[:110]
        pd.testing.assert_frame_equal(first, second)

    def test_flat_data_no_ranges(self):
        data = pd.DataFrame({"open": [10.0]*80, "high": [10.0]*80,
                             "low": [10.0]*80, "close": [10.0]*80})
        signals = extract_range_features(data, self.config)
        self.assertFalse(signals.range_qualified.any())

    def test_wilder_atr_constant_tr(self):
        n=40
        atr = wilder_atr(np.full(n, 101.), np.full(n, 99.),
                         np.full(n, 100.), 14)
        self.assertTrue(np.isnan(atr[:13]).all())
        self.assertTrue(np.allclose(atr[13:], 2.0))

    def test_selected_qualified_geometry(self):
        df = sample_data(130)
        f = extract_range_features(df, self.config)
        q = f[f.range_qualified]
        self.assertGreater(len(q), 0)
        self.assertTrue(((q.range_top > q.range_bottom) &
                         (q.equilibrium >= q.range_bottom) &
                         (q.equilibrium <= q.range_top)).all())
        self.assertTrue(q.scan_length.isin([10, 20, 30]).all())

    def test_rejects_invalid_ohlc(self):
        df = sample_data(40)
        df.loc[3, "high"] = -1
        with self.assertRaises(ValueError):
            extract_range_features(df, self.config)


if __name__ == "__main__":
    unittest.main()