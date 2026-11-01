"""The live EAs' Inputs dialog follows docs/ea-inputs.md: numbered groups from the fixed list, in order,
no input outside a group, every input labelled in at most 50 characters."""
import os
import re

import pytest

from make_live_sets import BASE, DARK_DEFAULTS

OWN_EAS = sorted(set(BASE) - set(DARK_DEFAULTS))     # Dark Moon and Rea are compiled vendor EAs: no source here, the guide does not apply
GROUPS = {1: "Trade size", 2: "Account protection", 3: "Orders", 4: "Identity and logs",
          5: "Strategy", 6: "Filters", 7: "Exits"}
MQL5 = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "mql5")


def dialog(path, seen=None):
    """(kind, text) rows in declaration order, local includes expanded in place: ("group", name) / ("input", label)."""
    seen = set() if seen is None else seen
    if path in seen:
        return []
    seen.add(path)
    rows = []
    for line in open(path, encoding="utf-8").read().splitlines():
        if m := re.match(r'\s*#include\s+"(.+?)"', line):
            rows += dialog(os.path.join(MQL5, m.group(1)), seen)
        elif m := re.match(r'\s*input\s+group\s+"(.*)"', line):
            rows.append(("group", m.group(1)))
        elif re.match(r"\s*s?input\s", line):
            m = re.search(r";\s*//\s*(.*?)\s*$", line)
            rows.append(("input", m.group(1) if m else ""))
    return rows


@pytest.mark.parametrize("ea", OWN_EAS)
def test_live_ea_inputs_follow_the_guide(ea):
    rows = dialog(os.path.join(MQL5, ea + ".mq5"))
    assert rows[0][0] == "group", f"{ea}: inputs before the first group"
    last = 0
    for kind, text in rows:
        if kind == "group":
            m = re.fullmatch(r"(\d)\. (.+)", text)
            assert m and GROUPS.get(int(m.group(1))) == m.group(2), f"{ea}: group {text!r} is not in the guide"
            assert int(m.group(1)) > last, f"{ea}: group {text!r} out of order"
            last = int(m.group(1))
        else:
            assert text, f"{ea}: an input has no label"
            assert len(text) <= 50, f"{ea}: label over 50 characters: {text!r}"
