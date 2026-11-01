"""The live sets and chart profiles carry every input an account needs, so nothing is typed in by hand.
NDX_Band_Breakout_EA: same clock on both brokers (New York + 7 h), different symbol and price scale."""
import os
import re

import pytest

import make_live_sets as L
from make_live_profiles import set_values

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EA = "NDX_Band_Breakout_EA"
PROFILE = {"atlas_2step_50k": "MBT_Atlas_2Step", "darwinex_zero": "MBT_DarwinexZero"}


def sets(folder):
    d = os.path.join(ROOT, "mql5", "sets", folder)
    return {f[:-4]: set_values(os.path.join(d, f)) for f in sorted(os.listdir(d)) if f.endswith(".set")}


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_ndx_set_matches_the_account(folder):
    _, daily, thr = L.ACCOUNTS[folder]
    v = sets(folder)[EA]
    assert (v["InpRiskMode"], v["InpRiskValue"]) == ("1", L.num(0.25 * L.RISK_SCALE[folder]))   # 0.25% of balance (add-on sizing) x the account's scale
    assert float(v["InpDailyLossPct"]) == daily and float(v["InpThrottleDDPct"]) == thr
    assert v["InpTimeframe"] == "1" and v["InpAllowShort"] == "false"                    # M1 signal bars, long only
    assert (v["InpOpenHour"], v["InpOpenMinute"], v["InpCloseHour"], v["InpCloseMinute"]) == ("16", "30", "22", "55")   # New York + 7 h on both brokers
    assert (v["InpEntryDelayMin"], v["InpBandMult"], v["InpTrendSMA"], v["InpStopPct"]) == ("60", "1.25", "400", "1.0")
    assert {k: v[k] for k in ("InpMaxSpreadPoints", "InpSlippagePoints")} == L.NDX_BROKER[folder]


def test_atlas_caps_are_ten_times_darwinex_caps():
    d, a = L.NDX_BROKER["darwinex_zero"], L.NDX_BROKER["atlas_2step_50k"]
    assert all(int(a[k]) == 10 * int(d[k]) for k in d)      # the Atlas symbol is taken to quote in 0.01 (to confirm), NDX on Darwinex in 0.1


def test_atlas_account_stays_inside_the_challenge_limits():
    _, daily, thr = L.ACCOUNTS["atlas_2step_50k"]
    assert 0 < daily < L.ATLAS["max_daily_loss_pct"]                                    # the EA's daily stop fires before Atlas's daily loss limit
    assert 0 < thr < L.ATLAS["max_loss_pct"]                                            # the throttle halves risk well before the static max loss


def test_atlas_dollar_limits_match_the_percent_limits():
    a = L.ATLAS                                                                         # the statistics page: breach at $46,000 and $2,000 a day
    assert a["floor_usd"] == a["initial_usd"] * (1 - a["max_loss_pct"] / 100)
    assert a["daily_usd"] == a["initial_usd"] * a["max_daily_loss_pct"] / 100
    assert a["day_reset_utc"] == "00:00"


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_magic_numbers_are_unique_per_account(folder):
    magics = [v["InpMagic"] for v in sets(folder).values() if "InpMagic" in v]
    assert len(magics) == len(set(magics)), magics


def test_chart_profiles_use_each_brokers_symbol():
    for folder, symbol in (("atlas_2step_50k", "NAS100"), ("darwinex_zero", "NDX")):
        d = os.path.join(ROOT, "mql5", "profiles", PROFILE[folder])
        found = []
        for f in sorted(os.listdir(d)):
            t = open(os.path.join(d, f), encoding="utf-16").read()
            if f"name={EA}\n" in t.replace("\r", ""):
                found.append(re.search(r"^symbol=(.*)$", t, re.M).group(1).strip())
        assert found == [symbol], (folder, found)


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_invictus_keeps_the_validated_lot_size(folder):
    # user, 2026-10-27: the validated 0.006 lot per $1,000 (not the 0.010 headline, 1.00 lot on ~100k), x the account's scale (Atlas 0.6, spec 2026-10-29)
    assert sets(folder)["Invictus_GBPJPY_Monday_EA"]["InpLotsPer1k"] == L.num(0.006 * L.RISK_SCALE[folder])


@pytest.mark.parametrize("folder", sorted(L.ACCOUNTS))
def test_risk_inputs_follow_the_account_scale(folder):
    s, k = sets(folder), L.RISK_SCALE[folder]
    for ea in L.GOLD:
        assert s[ea]["InpRiskValue"] == L.num(0.5 * k)
    assert s["Donchian_Trend_EA"]["InpRiskPercent"] == L.num(0.5 * k)
