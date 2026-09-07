extends Control
class_name BattleSceneController

signal battle_state_ready(model: BattleStateModel)
signal battle_command_requested(command_type: StringName)
signal battle_scene_finished(winner_side_id: StringName, reason: StringName)
signal round_resolved(messages: Array[String])

@export var auto_create_debug_state: bool = false

var battle_model: BattleStateModel
var turn_resolver: BattleTurnResolver = BattleTurnResolver.new()
var outcome_service: BattleOutcomeService = BattleOutcomeService.new()
var bond_service: BattleBondService = BattleBondService.new()
var _encounter_context: BattleEncounterContext = null
var _return_started: bool = false
var _result_overlay: PanelContainer = null
var _result_title: Label = null
var _result_body: Label = null
var _result_continue: Button = null
var _pending_winner: StringName = &""
var _pending_reason: StringName = &""
var _result_token: int = 0

@onready var battle_hud: BattleHUD = $BattleHUD
@onready var opponent_presenter: BattleStageCreatureWidget = $Stage/OpponentCreature
@onready var player_presenter: BattleStageCreatureWidget = $Stage/PlayerCreature
@onready var intro_fade: ColorRect = $IntroFade

func _ready() -> void:
    _build_result_overlay()
    battle_hud.command_requested.connect(_on_hud_command_requested)
    battle_hud.move_selected.connect(_on_move_selected)
    battle_hud.switch_selected.connect(_on_switch_selected)
    battle_hud.item_selected.connect(_on_item_selected)
    battle_hud.bond_attempt_requested.connect(_on_bond_attempt_requested)
    if BattleEncounterService.has_active_encounter():
        _setup_from_encounter_context()
    elif auto_create_debug_state:
        setup_battle(BattleStateFactory.create_debug_model())
    _start_scene_intro()

func _unhandled_input(event: InputEvent) -> void:
    if _result_overlay != null and _result_overlay.visible:
        var continue_pressed: bool = event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel")
        if InputMap.has_action(&"interact"):
            continue_pressed = continue_pressed or event.is_action_pressed(&"interact")
        if continue_pressed:
            _continue_from_result()
            get_viewport().set_input_as_handled()

func bind_player_inventory(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> void:
    turn_resolver.set_player_inventory(inventory, hotbar)
    battle_hud.bind_inventory(inventory, hotbar)

func setup_battle(model: BattleStateModel) -> bool:
    if battle_model != null:
        var refresh_callable: Callable = Callable(self, "_refresh_presentation")
        var finished_callable: Callable = Callable(self, "_on_battle_finished")
        if battle_model.is_connected(&"state_changed", refresh_callable):
            battle_model.disconnect(&"state_changed", refresh_callable)
        if battle_model.is_connected(&"battle_finished", finished_callable):
            battle_model.disconnect(&"battle_finished", finished_callable)
    if model == null or not model.is_valid_setup():
        battle_hud.set_message("Battle setup is invalid. Both sides need an active creature.")
        return false
    battle_model = model
    battle_model.state_changed.connect(_refresh_presentation)
    battle_model.battle_finished.connect(_on_battle_finished)
    battle_hud.bind_model(battle_model)
    _refresh_presentation()
    if battle_model.phase == BattleStateModel.PHASE_INITIALIZING:
        if not battle_model.begin_battle():
            battle_hud.set_message("Battle could not begin because the state model is invalid.")
            return false
    var start_messages: Array[String] = turn_resolver.begin_battle_effects(battle_model)
    if not start_messages.is_empty():
        battle_hud.set_message(_join_messages(start_messages, "\n"))
    battle_state_ready.emit(battle_model)
    return true

func get_state_model() -> BattleStateModel:
    return battle_model

func _refresh_presentation() -> void:
    if battle_model == null:
        opponent_presenter.bind_creature(null, false)
        player_presenter.bind_creature(null, true)
        return
    opponent_presenter.bind_creature(battle_model.get_opponent_active(), false)
    player_presenter.bind_creature(battle_model.get_player_active(), true)

func _on_hud_command_requested(command_type: StringName) -> void:
    if battle_model == null:
        battle_hud.set_message("No battle state is available.")
        return
    if command_type == BattleStateModel.COMMAND_BOND:
        battle_command_requested.emit(command_type)
        battle_hud.open_bond_panel(bond_service.get_attempt_info(battle_model))
        return
    if command_type == BattleStateModel.COMMAND_ESCAPE:
        battle_command_requested.emit(command_type)
        _resolve_player_action(BattleAction.escape_action(&"player", battle_model.get_player_active()))
        return
    battle_command_requested.emit(command_type)

func _on_move_selected(move_id: StringName) -> void:
    if battle_model == null or not battle_model.can_accept_player_command():
        return
    var active: BattleCreatureState = battle_model.get_player_active()
    if active == null:
        return
    battle_model.request_player_command(BattleStateModel.COMMAND_MOVES)
    battle_command_requested.emit(BattleStateModel.COMMAND_MOVES)
    _resolve_player_action(BattleAction.move_action(&"player", active, move_id))

func _on_switch_selected(index: int) -> void:
    if battle_model == null or not battle_model.can_accept_player_command():
        return
    var active: BattleCreatureState = battle_model.get_player_active()
    battle_model.request_player_command(BattleStateModel.COMMAND_SWITCH)
    battle_command_requested.emit(BattleStateModel.COMMAND_SWITCH)
    _resolve_player_action(BattleAction.switch_action(&"player", active, index))

func _on_item_selected(item_id: StringName, target_index: int) -> void:
    if battle_model == null or not battle_model.can_accept_player_command():
        return
    var active: BattleCreatureState = battle_model.get_player_active()
    battle_model.request_player_command(BattleStateModel.COMMAND_ITEM)
    battle_command_requested.emit(BattleStateModel.COMMAND_ITEM)
    _resolve_player_action(BattleAction.item_action(&"player", active, item_id, target_index))

func _on_bond_attempt_requested(paid_retry: bool) -> void:
    if battle_model == null or not battle_model.can_accept_player_command():
        return
    var active: BattleCreatureState = battle_model.get_player_active()
    battle_model.request_player_command(BattleStateModel.COMMAND_BOND)
    var result: Dictionary = bond_service.attempt(battle_model, _encounter_context, paid_retry)
    var message: String = str(result.get("message", ""))
    if bool(result.get("success", false)):
        battle_hud.close_bond_panel()
        if not message.is_empty():
            battle_hud.set_message(message)
        return
    if not bool(result.get("resolved", false)):
        battle_hud.set_message(message)
        battle_hud.open_bond_panel(bond_service.get_attempt_info(battle_model))
        return
    battle_hud.close_bond_panel()
    var opponent_action: BattleAction = BattleOpponentPolicy.choose_action(battle_model, battle_model.opponent_ai_profile_id)
    var messages: Array[String] = turn_resolver.resolve_round(battle_model, BattleAction.bond_action(&"player", active), opponent_action)
    if not message.is_empty():
        messages.push_front(message)
    if not messages.is_empty():
        battle_hud.set_message(_join_messages(messages, "\n"))
    round_resolved.emit(messages)

func _resolve_player_action(player_action: BattleAction) -> void:
    if battle_model == null or player_action == null or battle_model.is_finished():
        return
    var opponent_action: BattleAction = BattleOpponentPolicy.choose_action(battle_model, battle_model.opponent_ai_profile_id)
    var messages: Array[String] = turn_resolver.resolve_round(battle_model, player_action, opponent_action)
    if not messages.is_empty():
        battle_hud.set_message(_join_messages(messages, "\n"))
    round_resolved.emit(messages)

func _on_battle_finished(winner_side_id: StringName, reason: StringName) -> void:
    var outcome_message: String = ""
    if battle_model != null and not battle_model.outcome_committed:
        var outcome: Dictionary = outcome_service.commit(battle_model)
        battle_model.outcome_committed = bool(outcome.get("committed", false))
        outcome_message = str(outcome.get("message", ""))
    battle_scene_finished.emit(winner_side_id, reason)
    if _encounter_context != null:
        _show_result_overlay(winner_side_id, reason, outcome_message)
    elif not outcome_message.is_empty():
        battle_hud.set_message(outcome_message)

func _join_messages(messages: Array[String], separator: String) -> String:
    var result: String = ""
    for index: int in range(messages.size()):
        if index > 0:
            result += separator
        result += messages[index]
    return result

func _setup_from_encounter_context() -> void:
    _encounter_context = BattleEncounterService.get_active_context()
    if _encounter_context == null or not _encounter_context.is_valid():
        battle_hud.set_message("Battle encounter context is invalid.")
        return
    var model: BattleStateModel = BattleStateFactory.create_from_player_party(_encounter_context.opponent_species_ids, _encounter_context.encounter_kind, _encounter_context.environment_id)
    var inventory: InventoryComponent = InventoryComponent.new()
    inventory.sync_with_game_session = true
    add_child(inventory)
    var hotbar: HotbarComponent = HotbarComponent.new()
    hotbar.sync_with_game_session = true
    add_child(hotbar)
    bind_player_inventory(inventory, hotbar)
    setup_battle(model)

func _start_scene_intro() -> void:
    if intro_fade == null:
        return
    intro_fade.modulate = Color.WHITE
    var tween: Tween = create_tween()
    tween.tween_interval(0.08)
    tween.tween_property(intro_fade, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.34)
    tween.tween_callback(Callable(intro_fade, "queue_free"))

func _show_result_overlay(winner_side_id: StringName, reason: StringName, outcome_message: String) -> void:
    _pending_winner = winner_side_id
    _pending_reason = reason
    _result_title.text = _result_title_text(winner_side_id, reason)
    var body: String = outcome_message
    if body.is_empty():
        body = _build_return_message(winner_side_id, reason)
    _result_body.text = "%s\n\nContinue [E / Enter]" % body
    _result_overlay.visible = true
    _result_continue.grab_focus()
    _result_token = Time.get_ticks_msec()
    call_deferred("_auto_continue_result", _result_token)

func _auto_continue_result(token: int) -> void:
    await get_tree().create_timer(4.0).timeout
    if _result_overlay != null and _result_overlay.visible and token == _result_token:
        _continue_from_result()

func _continue_from_result() -> void:
    if _return_started or _encounter_context == null:
        return
    _return_started = true
    if _result_continue != null:
        _result_continue.disabled = true
    _return_to_encounter_source(_pending_winner, _pending_reason)

func _return_to_encounter_source(winner_side_id: StringName, reason: StringName) -> void:
    if _encounter_context == null:
        return
    var context: BattleEncounterContext = _encounter_context
    var return_scene: String = context.source_scene_path
    var return_spawn: StringName = &"battle_return"
    var returning_to_source: bool = true
    if winner_side_id == &"opponent":
        return_scene = SceneRouter.DEFAULT_SCENE_PATH
        return_spawn = &"default"
        returning_to_source = return_scene == context.source_scene_path
    if returning_to_source:
        var result_data: Dictionary = {
            "spawn_token": context.source_spawn_token,
            "remove_spawn": winner_side_id == &"player" and reason != &"escaped",
        }
        GameSession.set_value(&"pending_battle_return", result_data)
    else:
        GameSession.set_value(&"pending_battle_return", {})
    BattleEncounterService.clear_active_encounter()
    var error: Error = SceneRouter.change_scene(return_scene, return_spawn)
    if error != OK:
        _return_started = false
        if _result_continue != null:
            _result_continue.disabled = false
        _result_body.text = "Could not return to the world. Press Continue to retry."

func _build_return_message(winner_side_id: StringName, reason: StringName) -> String:
    if reason == &"bonded":
        return "Bond formed. The creature joined your collection."
    if winner_side_id == &"player":
        return "Victory. Rewards have been applied."
    if reason == &"escaped":
        return "Escaped safely."
    return "Defeat. Your party recovered at the homestead."

func _result_title_text(winner_side_id: StringName, reason: StringName) -> String:
    if reason == &"bonded":
        return "BOND FORMED"
    if reason == &"escaped":
        return "ESCAPED"
    if winner_side_id == &"player":
        return "VICTORY"
    return "DEFEAT"

func _build_result_overlay() -> void:
    _result_overlay = PanelContainer.new()
    _result_overlay.set_anchors_preset(Control.PRESET_CENTER)
    _result_overlay.position = Vector2(-250, -135)
    _result_overlay.custom_minimum_size = Vector2(500, 270)
    _result_overlay.visible = false
    _result_overlay.z_index = 100
    add_child(_result_overlay)
    LungSaUIStyle.apply_panel(_result_overlay, true)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    _result_overlay.add_child(margin)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    margin.add_child(box)

    _result_title = Label.new()
    _result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _result_title.add_theme_font_size_override("font_size", 30)
    box.add_child(_result_title)

    _result_body = Label.new()
    _result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _result_body.add_theme_font_size_override("font_size", 16)
    _result_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(_result_body)

    _result_continue = Button.new()
    _result_continue.text = "Continue"
    _result_continue.custom_minimum_size = Vector2(180, 44)
    _result_continue.pressed.connect(_continue_from_result)
    LungSaUIStyle.apply_button(_result_continue, true)
    box.add_child(_result_continue)
