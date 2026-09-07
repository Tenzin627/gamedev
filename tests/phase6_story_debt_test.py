#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def int_value(source: str, pattern: str) -> int:
    match = re.search(pattern, source)
    assert match, pattern
    return int(match.group(1))

debt = text("systems/progression/debt_service.gd")
main_quest = text("data/quests/receipt_that_bites_back.tres")
side_quest = text("data/quests/lucky_bowl.tres")
wager = text("world/shared/story/village_wager_table.gd")
profile = text("data/profiles/active_game_profile.tres")
village = text("world/central_basin/zones/demo_village.tscn")
tracker = text("ui/quests/quest_tracker_widget.gd")

initial_total = int_value(debt, r"INITIAL_TOTAL_DEBT: int = (\d+)")
first_due = int_value(debt, r"FIRST_INSTALLMENT: int = (\d+)")
main_reward = int_value(main_quest, r"reward_currency = (\d+)")
side_reward = int_value(side_quest, r"reward_currency = (\d+)")
stake = int_value(wager, r"STAKE: int = (\d+)")
payout = int_value(wager, r"WIN_PAYOUT: int = (\d+)")

assert initial_total == 100000
assert first_due == 500
assert initial_total - first_due == 99500
assert main_reward == 425
assert side_reward == 10
assert stake == 20
assert payout == 80
assert 'WIN_CHANCE: float = 0.55' in wager
assert 'randf() < WIN_CHANCE' in wager
assert 'int(GameSession.get_value(PLAYED_KEY, 0)) > 0' in wager
assert 'primary_story_chain_id = &"story_chain.central_basin.first_collection"' in profile
assert 'LedgerPaymentDesk' in village and 'LuckyBowl' in village
payment_desk = text("world/shared/story/debt_payment_desk.gd")
assert 'DebtService.pay_current_due()' in payment_desk
assert 'MAIN_QUEST_ID' in payment_desk and 'STATUS_COMPLETED' in payment_desk
assert 'post_quest_hint' in tracker
assert 'Story, debt, and wagering arrive in later phases.' not in text("presentation/slice_menu.gd")
assert 'slice.welcomed' in text("vertical_slice/demo_story_coordinator.gd")
assert 'slice_restart_requested' in text("vertical_slice/demo_story_coordinator.gd")
assert 'QuestObjectiveDefinition.Kind.BOND_CREATURE' not in text("systems/battle/battle_bond_service.gd") or 'QuestService.notify_event(QuestObjectiveDefinition.Kind.BOND_CREATURE' in text("systems/battle/battle_bond_service.gd")

# Phase 3's conservative short-loop gain was 63. The main quest must make the
# collection reachable through ordinary play even after one 25-coin Bond retry.
start_currency = 40
conservative_phase3_gain = 63
paid_bond_retry = 25
ordinary_total = start_currency + conservative_phase3_gain + main_reward - paid_bond_retry
assert ordinary_total >= first_due, ordinary_total

# The optional wager is genuinely optional; even a loss plus its quest reward
# cannot be required for the normal path above.
loss_net = side_reward - stake
win_net = side_reward - stake + payout
assert loss_net == -10
assert win_net == 70

print(
    "PHASE 6 STORY/DEBT: PASS | "
    f"debt={first_due}/{initial_total} remaining={initial_total-first_due} | "
    f"main_reward={main_reward} ordinary_after_retry={ordinary_total} | "
    f"wager_net=loss {loss_net}/win {win_net}"
)
