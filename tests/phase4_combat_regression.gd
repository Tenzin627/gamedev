extends Node

var failures: Array[String] = []

func check(value: bool, label: String) -> void:
    if not value:
        failures.append(label)
    print(("PASS " if value else "FAIL ") + label)

func _ready() -> void:
    var profile: GameProfileDefinition = ContentDB.get_active_profile()
    check(profile != null, "Active profile loads")
    if profile == null:
        get_tree().quit(1)
        return

    GameSession.start_new_session(String(profile.content_id))
    DemoBootstrap._ensure_starter_creatures(profile)

    var opponents: Array[StringName] = [&"creature.brambleback.baby"]
    var model: BattleStateModel = BattleStateFactory.create_from_player_party(opponents, &"wild", &"region.central_basin")
    check(model.is_valid_setup(), "Wild battle model is valid")
    check(model.player_team.creatures.size() == 2, "Starter battle party has two creatures")
    check(model.player_team.creatures[0].archetype == &"guard", "Mossback starter is Guard")
    check(model.player_team.creatures[1].archetype == &"speed", "Rillfin starter is Speed")
    check(model.get_opponent_active().archetype == &"attack", "Brambleback wild target is Attack")
    check(model.begin_battle(), "Battle begins")

    var resolver: BattleTurnResolver = BattleTurnResolver.new()
    var active: BattleCreatureState = model.get_player_active()
    var enemy_before: int = model.get_opponent_active().current_hp
    resolver.resolve_round(model, BattleAction.move_action(&"player", active, &"move.nudge"), null)
    var guard_vs_attack_damage: int = enemy_before - model.get_opponent_active().current_hp
    check(guard_vs_attack_damage >= 8, "Guard deals archetype-advantaged damage to Attack")

    active = model.get_player_active()
    resolver.resolve_round(model, BattleAction.switch_action(&"player", active, 1), null)
    check(model.player_team.active_index == 1, "Switch changes active creature")
    check(model.player_team.switch_cooldown_turns_remaining == 1, "Switch starts one-turn cooldown")

    active = model.get_player_active()
    resolver.resolve_round(model, BattleAction.move_action(&"player", active, &"move.bark_brace"), null)
    check(model.player_team.switch_cooldown_turns_remaining == 0, "One non-switch turn clears cooldown")

    var bond_model: BattleStateModel = BattleStateFactory.create_from_player_party(opponents, &"wild", &"region.central_basin")
    check(bond_model.begin_battle(), "Bond test battle begins")
    bond_model.bond_standard_attempt_used = true
    bond_model.bond_paid_attempts = 1
    GameSession.set_value(&"currency", 100)
    var bond_service: BattleBondService = BattleBondService.new()
    var bond_result: Dictionary = bond_service.attempt(bond_model, null, true)
    check(not bool(bond_result.get("resolved", true)), "Second paid Bond retry is rejected")
    check(int(GameSession.get_value(&"currency", 0)) == 100, "Rejected Bond retry charges no currency")

    print("PHASE 4 COMBAT REGRESSION: %s (%d failures)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if failures.is_empty() else 1)
