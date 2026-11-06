import pytest

import sweep as S

ARGS = ["--expert", "MACD_Cross_EA", "--from", "2025-01-01", "--to", "2026-10-01"]


def test_grid_size_counts_inclusive_steps_and_multiplies():
    assert S.grid_size({"InpRiskValue": ("0.5", "0.5", "2.0")}) == 4
    assert S.grid_size({"InpStopLossPct": ("0.3", "0.1", "0.6")}) == 4          # float step: 0.3/0.1 steps must not lose the last
    assert S.grid_size({"A": ("0", "1", "3"), "B": ("2", "1", "4")}) == 12


def test_free_pct_reads_memory_pressure_text():
    assert S.free_pct("The system has 19327352832 (1179648 pages)\nSystem-wide memory free percentage: 25%\n") == 25
    assert S.free_pct("no such line") is None


def test_more_passes_than_the_cap_is_refused_before_anything_runs(monkeypatch):
    monkeypatch.setattr(S, "mt5_running", lambda: pytest.fail("must refuse on the cap first"))
    with pytest.raises(SystemExit, match="5 passes is more than --max-passes 4"):
        S.main(ARGS + ["--range", "InpRiskValue=0.5:0.5:2.5"])


def test_mt5_running_matches_wine_processes_not_a_shell_that_names_them(monkeypatch):
    class Ps:
        def __init__(self, text):
            self.stdout = text
    wine = "C:\\Program Files\\MetaTrader 5\\terminal64.exe \nC:/Program Files/MetaTrader 5/terminal64.exe /portable /config:Z:\\x.ini"
    shell = "/bin/zsh -c ps -axo command | grep -E 'metatester64|terminal64' ; echo terminal64.exe"
    monkeypatch.setattr(S.subprocess, "run", lambda *a, **k: Ps(wine))
    assert S.mt5_running()
    monkeypatch.setattr(S.subprocess, "run", lambda *a, **k: Ps(shell))
    assert not S.mt5_running()


def test_open_terminal_is_refused(monkeypatch):
    monkeypatch.setattr(S, "mt5_running", lambda: True)
    with pytest.raises(SystemExit, match="MT5 is running"):
        S.main(ARGS + ["--range", "InpRiskValue=0.5:0.5:2.0"])


def test_unknown_input_is_refused(monkeypatch):
    with pytest.raises(SystemExit, match="unknown input"):
        S.main(ARGS + ["--range", "InpRiskValue=0.5:0.5:2.0", "--set", "NoSuchInput=1"])


def test_cleanup_deletes_old_days_and_truncates_today(tmp_path):
    for d in ("logs", "Agent-127.0.0.1-3000/logs", "Agent-127.0.0.1-3001/logs"):
        (tmp_path / d).mkdir(parents=True)
    old = [tmp_path / "logs" / "20261028.log", tmp_path / "Agent-127.0.0.1-3000" / "logs" / "20261028.log"]
    new = [tmp_path / "logs" / "20261030.log", tmp_path / "Agent-127.0.0.1-3000" / "logs" / "20261030.log"]
    keep = tmp_path / "logs" / "report.htm"
    for f in old + new + [keep]:
        f.write_text("data")
    S.cleanup_logs(str(tmp_path))
    assert not any(f.exists() for f in old)
    assert all(f.exists() and f.stat().st_size == 0 for f in new)
    assert keep.read_text() == "data"


def test_table_shows_net_in_usd_and_percent_of_deposit():
    passes = [{"InpRiskValue": 0.5, "Profit": 186204.12, "Profit Factor": 1.9, "Trades": 120.0, "Equity DD %": 12.3,
               "Recovery Factor": 3.1, "Sharpe Ratio": 2.2}]
    out = S.table(passes, {"InpRiskValue": ("0.5", "0.5", "2.0")}, 100000).splitlines()
    assert out[0].split() == ["InpRiskValue", "Profit", "Profit", "Factor", "Trades", "Equity", "DD", "%", "Recovery",
                              "Factor", "Sharpe", "Ratio", "Net", "%"]
    assert out[1].split()[:2] == ["0.5", "186204.12"] and out[1].split()[-1] == "+186.2"
