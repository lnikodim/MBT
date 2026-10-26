"""Logging-only amendment for third-party EAs that flood the tester log (user rule, 2026-10-26: "when you detect EAs that heavily use
logging, clean up the logs from the core logic if they are not necessary for the strategy").

Print / PrintFormat / printf / Alert calls are renamed to NoLog, a do-nothing function that takes up to 16 arguments. The arguments are still evaluated,
so any side effect in them is kept; only the log write is gone. Renaming (instead of deleting the call) keeps `if (x) Print(...);` valid.
Comments and string literals are left alone.

  python3 scripts/strip_logging.py mql5/CB20424_EA.mq5          # writes mql5/CB20424_EA.mq5.orig and strips in place
"""
import re, sys, os, shutil

CALL = re.compile(r"\b(Print|PrintFormat|printf|Alert)(\s*\()")
WRAPPER = ('//--- MBT logging-only amendment: Print, PrintFormat, printf and Alert are renamed NoLog (arguments still evaluated, nothing written)\n'
           'void NoLog(string a="",string b="",string c="",string d="",string e="",string f="",string g="",string h="",\n'
           '           string i="",string j="",string k="",string l="",string m="",string n="",string o="",string p="") {}\n')


def mask(s):
    """s with the inside of comments and string literals blanked (same length), so a regex only sees code."""
    out, i, n = list(s), 0, len(s)
    while i < n:
        if s.startswith("//", i):
            j = s.find("\n", i); j = n if j < 0 else j
            out[i:j] = " " * (j - i); i = j
        elif s.startswith("/*", i):
            j = s.find("*/", i + 2); j = n if j < 0 else j + 2
            for k in range(i, j):
                if s[k] != "\n": out[k] = " "
            i = j
        elif s[i] == '"':
            j = i + 1
            while j < n and s[j] != '"':
                j += 2 if s[j] == "\\" else 1
            for k in range(i + 1, min(j, n)): out[k] = " "
            i = j + 1
        elif s[i] == "'":
            j = i + 1
            while j < n and s[j] != "'":
                j += 2 if s[j] == "\\" else 1
            for k in range(i + 1, min(j, n)): out[k] = " "
            i = j + 1
        else:
            i += 1
    return "".join(out)


def strip_text(s):
    """(new text, number of calls renamed). The wrapper goes after the last #include / #property / #import / #define of the file's header."""
    m = mask(s)
    hits = list(CALL.finditer(m))
    if not hits:
        return s, 0
    parts, last = [], 0
    for h in hits:
        parts.append(s[last:h.start(1)]); parts.append("NoLog"); last = h.end(1)
    s2 = "".join(parts) + s[last:]
    lines = s2.split("\n")
    head = 0
    for idx, line in enumerate(lines[:120]):
        if re.match(r"\s*#(include|property|import|define)\b", line):
            head = idx + 1
    return "\n".join(lines[:head]) + "\n" + WRAPPER + "\n".join(lines[head:]), len(hits)


def strip_file(path):
    """Strip in place, keeping the original beside it as <path>.orig. Returns the number of calls renamed."""
    raw = open(path, "rb").read()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig", "ignore")
    new, n = strip_text(text)
    if n:
        shutil.copyfile(path, path + ".orig")
        with open(path, "wb") as f:
            f.write((b"\xef\xbb\xbf" if bom else b"") + new.encode("utf-8"))
    return n


def restore(path):
    if os.path.exists(path + ".orig"):
        shutil.move(path + ".orig", path)


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, strip_file(p), "calls renamed")
