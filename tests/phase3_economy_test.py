#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def value(path: str, key: str) -> int:
    text = (ROOT / path).read_text()
    m = re.search(rf"^{re.escape(key)} = (\d+)$", text, re.M)
    if not m:
        raise AssertionError(f"{path}: missing {key}")
    return int(m.group(1))

prices = {
    "wood": value("data/items/basin_wood.tres", "sell_value"),
    "fiber": value("data/items/plant_fiber.tres", "sell_value"),
    "stone": value("data/items/river_stone.tres", "sell_value"),
    "herb": value("data/items/wild_herb.tres", "sell_value"),
    "moonroot": value("data/items/moonroot.tres", "sell_value"),
    "sunpod": value("data/items/sunpod.tres", "sell_value"),
}

# Conservative short-loop minimum: 2 Moonroot, 2 Wood, 1 Fiber, 2 Stone,
# 1 Herb, 2 Sunpod. It should feel meaningful relative to 40 starting currency.
minimum_gain = (2 * prices["moonroot"] + 2 * prices["wood"] + prices["fiber"]
                + 2 * prices["stone"] + prices["herb"] + 2 * prices["sunpod"])
assert minimum_gain >= 55, f"Phase 3 minimum loop only earns {minimum_gain}; target >= 55"
assert value("data/farming/sunpod_seed.tres", "sell_value") == 0
assert value("data/farming/moonroot_seed.tres", "sell_value") == 0
for tool in ("field_hoe", "watering_can", "field_axe", "field_pickaxe"):
    assert value(f"data/items/{tool}.tres", "sell_value") == 0, f"{tool} must be protected"
print(f"PHASE 3 ECONOMY: PASS | conservative short-loop gain={minimum_gain} | start=40")
