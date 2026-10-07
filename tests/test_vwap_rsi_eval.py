import subprocess

import pytest

import vwap_rsi_eval as E


def fake_lsof(output):
    calls = []

    def run(cmd, *a, **k):
        calls.append(list(cmd))
        return subprocess.CompletedProcess(cmd, 0, stdout=output if cmd[0] == "lsof" else "", stderr="")
    return calls, run


def test_agent_ports_never_kills_and_refuses_when_busy(monkeypatch):
    calls, run = fake_lsof("p123\ncnode\nn*:3000\n")
    monkeypatch.setattr(E.subprocess, "run", run)
    monkeypatch.setenv("MBT_FREE_PORTS", "1")                     # the old opt-in must not bring killing back
    with pytest.raises(SystemExit, match="123:node"):
        E.free_agent_ports()
    assert all(c[0] != "kill" for c in calls)


def test_agent_ports_pass_when_free(monkeypatch):
    calls, run = fake_lsof("")
    monkeypatch.setattr(E.subprocess, "run", run)
    E.free_agent_ports()
    assert all(c[0] != "kill" for c in calls)


def test_agent_ports_ignore_wine_owned_sockets(monkeypatch):
    # under Wine every Windows socket (MT5's own tester agents) shows up as owned by wineserver
    calls, run = fake_lsof("p43429\ncwineserver\nn127.0.0.1:3008\n")
    monkeypatch.setattr(E.subprocess, "run", run)
    E.free_agent_ports()                                            # must not refuse
    assert all(c[0] != "kill" for c in calls)


def test_agent_ports_allow_ipv6_loopback_servers(monkeypatch):
    # a dev server bound to [::1] coexists with MT5's agents on 127.0.0.1 (tested 2026-10-07)
    calls, run = fake_lsof("p48560\ncnode\nn[::1]:3000\np50772\ncnode\nn[::1]:3001\n")
    monkeypatch.setattr(E.subprocess, "run", run)
    E.free_agent_ports()


def test_agent_ports_refuse_dual_stack_servers(monkeypatch):
    calls, run = fake_lsof("p50772\ncnode\nn*:3001\n")
    monkeypatch.setattr(E.subprocess, "run", run)
    with pytest.raises(SystemExit, match="50772:node"):
        E.free_agent_ports()
