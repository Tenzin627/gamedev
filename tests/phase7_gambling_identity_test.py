#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

wager = text("world/shared/story/village_wager_table.gd")
side_quest = text("data/quests/lucky_bowl.tres")
fortune = text("ui/shared/fortune_reveal_panel.gd")
core_hud = text("ui/hud/core_hud.gd")
debt_tracker = text("ui/hud/debt_tracker_widget.gd")
bond_panel = text("ui/creatures/bond_encounter_panel.gd")
story = text("vertical_slice/demo_story_coordinator.gd")

assert 'class_name FortuneRevealPanel' in fortune
assert 'show_fortune_reveal(' in core_hud
assert '_pending_reward_reveal' in core_hud
assert 'COLLECTION 01' in debt_tracker and 'FundsBar' in debt_tracker
assert 'BOND WAGER' in bond_panel and 'TEMPT FATE' in bond_panel
assert 'INHERITANCE DRAW' in story and '+1 FARM  •  +100,000 DEBT' in story

stake = int(re.search(r'STAKE: int = (\d+)', wager).group(1))
payout = int(re.search(r'WIN_PAYOUT: int = (\d+)', wager).group(1))
stipend = int(re.search(r'RESEARCH_STIPEND: int = (\d+)', wager).group(1))
reward = int(re.search(r'reward_currency = (\d+)', side_quest).group(1))
chance = float(re.search(r'WIN_CHANCE: float = ([0-9.]+)', wager).group(1))

assert stake == 20
assert payout == 80
assert stipend == 10
assert reward == stipend
assert chance == 0.55
assert 'ODDS 55%%' in wager
assert 'randf() < WIN_CHANCE' in wager
assert reward - stake == -10
assert reward - stake + payout == 70
assert '+70 NET' in wager and '-10 NET' in wager

print(
    "PHASE 7 GAMBLING IDENTITY: PASS | "
    f"odds={int(chance*100)}% stake={stake} payout={payout} stipend={stipend} "
    f"net=loss {reward-stake}/win {reward-stake+payout}"
)
