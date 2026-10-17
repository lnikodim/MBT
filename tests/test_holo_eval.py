import holo_eval as H


def test_agent_log_since_reads_a_restarted_log_from_the_start(tmp_path, monkeypatch):
    monkeypatch.setattr(H, "AGENT_LOG", str(tmp_path) + "/")
    log = tmp_path / "20261017.log"
    log.write_bytes(b"\xff\xfe" + "old run\n".encode("utf-16-le") * 50)
    mark = H.agent_log_size()
    log.write_bytes(b"\xff\xfe" + "new run\n".encode("utf-16-le"))   # MT5 restarted the file
    assert H.agent_log_since(mark) == "new run\n"
    with open(log, "ab") as h:
        h.write("appended\n".encode("utf-16-le"))
    assert H.agent_log_since(H.agent_log_size()) == ""
