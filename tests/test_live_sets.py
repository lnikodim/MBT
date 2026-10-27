"""The live sets and chart profiles carry every input an account needs, so nothing is typed in by hand.
NDX_Band_Breakout_EA: same clock on both brokers (New York + 7 h), different symbol and price scale."""
import os
import re

import pytest

import make_live_sets as L
from make_live_profiles import set_values

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EA = "NDX_Band_Breakout_EA"
PROFILE = {"ftmo_2step_50k": "MBT_FTMO_2Step", "darwinex_zero": "MBT_DarwinexZero"}


def sets(folder):
    d = os.path.join(ROOT, "mql5", "sets", folder)
    return {f[:-4]: set_values(os.path.join(d, f)) for f in sorted(os.listdir(d)) if f.endswith(".set")}


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_ndx_set_matches_the_account(folder):
    _, daily, thr = L.ACCOUNTS[folder]
    v = sets(folder)[EA]
    assert (v["InpRiskMode"], v["InpRiskValue"]) == ("1", "0.25")                       # 0.25% of balance: add-on sizing
    assert float(v["InpDailyLossPct"]) == daily and float(v["InpThrottleDDPct"]) == thr
    assert v["InpTimeframe"] == "1" and v["InpAllowShort"] == "false"                    # M1 signal bars, long only
    assert (v["InpOpenHour"], v["InpOpenMinute"], v["InpCloseHour"], v["InpCloseMinute"]) == ("16", "30", "22", "55")   # New York + 7 h on both brokers
    assert (v["InpEntryDelayMin"], v["InpBandMult"], v["InpTrendSMA"], v["InpStopPct"]) == ("60", "1.25", "400", "1.0")
    assert {k: v[k] for k in ("InpMaxSpreadPoints", "InpSlippagePoints")} == L.NDX_BROKER[folder]


def test_ftmo_caps_are_ten_times_darwinex_caps():
    d, f = L.NDX_BROKER["darwinex_zero"], L.NDX_BROKER["ftmo_2step_50k"]
    assert all(int(f[k]) == 10 * int(d[k]) for k in d)      # US100.cash is taken to quote in 0.01, NDX on Darwinex in 0.1


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_magic_numbers_are_unique_per_account(folder):
    magics = [v["InpMagic"] for v in sets(folder).values() if "InpMagic" in v]
    assert len(magics) == len(set(magics)), magics


def test_chart_profiles_use_each_brokers_symbol():
    for folder, symbol in (("ftmo_2step_50k", "US100.cash"), ("darwinex_zero", "NDX")):
        d = os.path.join(ROOT, "mql5", "profiles", PROFILE[folder])
        found = []
        for f in sorted(os.listdir(d)):
            t = open(os.path.join(d, f), encoding="utf-16").read()
            if f"name={EA}\n" in t.replace("\r", ""):
                found.append(re.search(r"^symbol=(.*)$", t, re.M).group(1).strip())
        assert found == [symbol], (folder, found)


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_invictus_keeps_the_validated_lot_size(folder):
    assert sets(folder)["Invictus_GBPJPY_Monday_EA"]["InpLotsPer1k"] == "0.006"       # user, 2026-10-27: not the 0.010 headline (1.00 lot on ~100k)
