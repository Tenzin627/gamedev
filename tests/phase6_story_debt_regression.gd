extends Node

func _ready() -> void:
    var failures: Array[String] = []
    var profile: GameProfileDefinition = ContentDB.get_active_profile()
    _expect(profile != null, "Active profile missing", failures)
    if profile != null:
        _expect(profile.primary_story_chain_id == &"story_chain.central_basin.first_collection", "Phase 6 story chain is not active", failures)

    var main_quest: QuestDefinition = ContentDB.get_definition(&"quest.central_basin.receipt_that_bites_back") as QuestDefinition
    _expect(main_quest != null, "Main Phase 6 quest missing", failures)
    if main_quest != null:
        _expect(main_quest.reward_currency == 425, "Main quest reward must be 425", failures)
        var has_talk: bool = false
        var has_bond: bool = false
        var has_return: bool = false
        for objective: QuestObjectiveDefinition in main_quest.objectives:
            if objective == null:
                continue
            has_talk = has_talk or objective.kind == QuestObjectiveDefinition.Kind.TALK_TO_NPC
            has_bond = has_bond or objective.kind == QuestObjectiveDefinition.Kind.BOND_CREATURE
            has_return = has_return or objective.kind == QuestObjectiveDefinition.Kind.SESSION_COUNTER
        _expect(has_talk and has_bond and has_return, "Main quest must cover talk → Bond → return", failures)

    var side_quest: QuestDefinition = ContentDB.get_definition(&"quest.central_basin.lucky_bowl") as QuestDefinition
    _expect(side_quest != null and side_quest.reward_currency == 10, "Lucky Bowl side quest/reward must be 10 after Phase 7 risk tuning", failures)

    GameSession.start_new_session("phase6_regression")
    DebtService.initialize_if_needed()
    _expect(DebtService.get_current_due() == 500, "First collection must be 500", failures)
    _expect(DebtService.get_remaining_total() == 100000, "Initial Ledger balance must be 100000", failures)
    GameSession.set_value(&"currency", 499)
    _expect(not DebtService.pay_current_due(), "Debt payment must reject wallets below 500", failures)
    _expect(int(GameSession.get_value(&"currency", 0)) == 499, "Rejected payment changed currency", failures)
    GameSession.set_value(&"currency", 500)
    _expect(DebtService.pay_current_due(), "500-coin payment should succeed", failures)
    _expect(int(GameSession.get_value(&"currency", -1)) == 0, "Payment did not deduct exactly 500", failures)
    _expect(DebtService.get_remaining_total() == 99500, "Remaining debt must be 99500", failures)
    _expect(DebtService.is_first_payment_complete(), "First payment completion state missing", failures)

    if failures.is_empty():
        print("PHASE 6 STORY/DEBT REGRESSION: PASS")
    else:
        for failure: String in failures:
            push_error("PHASE 6 STORY/DEBT: %s" % failure)

    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
