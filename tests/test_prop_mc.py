import numpy as np

import prop_mc as PM


def _run(day_R, throttle=None, seed=7, **kw):
    args = dict(risk=1.0, target=10, daily=5, max_loss=10, min_days=1, horizon=200, trailing=False, n=2000)
    args.update(kw)
    return PM.challenge(day_R, rng=np.random.default_rng(seed), throttle=throttle, **args)


def test_throttle_off_and_factor_one_match_the_unthrottled_run():
    days = [np.array([1.0, -1.0]), np.array([-2.0]), np.array([1.5]), np.array([-0.5, 2.0])]
    base = _run(days)
    assert _run(days, throttle=None) == base
    assert _run(days, throttle=[3.0, 1.0]) == base     # factor 1 changes nothing and draws no extra randoms


def test_throttle_halves_trades_once_the_drawdown_reaches_the_threshold():
    # one day: -2R, -2R, +10R at 1% risk. Unthrottled: 0.98 * 0.98 * 1.10 = 1.0564 -> a 5% target is reached.
    # Throttled at 3% / 0.5: the +10R trade comes at a 3.96% drawdown, so it counts as +5R:
    # 0.98 * 0.98 * 1.05 = 1.0084 -> no pass. A 5% threshold is not reached (3.96%), so that run passes.
    days = [np.array([-2.0, -2.0, 10.0])]
    run = lambda thr: _run(days, throttle=thr, risk=1.0, target=5, daily=100, max_loss=100, horizon=1, n=10)
    assert run(None)["p_pass"] == 1.0
    assert run([3.0, 0.5])["p_pass"] == 0.0 and run([3.0, 0.5])["p_no_result"] == 1.0
    assert run([5.0, 0.5])["p_pass"] == 1.0
