extends Control
class_name BattleHUD

signal command_requested(command_type: StringName)
signal move_selected(move_id: StringName)
signal switch_selected(index: int)
signal item_selected(item_id: StringName, target_index: int)
signal bond_attempt_requested(paid_retry: bool)

var battle_model: BattleStateModel

@onready var opponent_status: BattleCreatureStatusWidget = $OpponentStatus
@onready var opponent_party: BattlePartyStripWidget = $OpponentParty
@onready var player_status: BattleCreatureStatusWidget = $PlayerStatus
@onready var player_party: BattlePartyStripWidget = $PlayerParty
@onready var command_menu: BattleCommandMenu = $CommandMenu
@onready var action_picker: BattleActionPicker = $ActionPicker
@onready var encounter_panel: PanelContainer = $EncounterHeader
@onready var encounter_label: Label = $EncounterHeader/Margin/VBox/Encounter
@onready var phase_label: Label = $EncounterHeader/Margin/VBox/Phase
@onready var rule_hint: Label = $EncounterHeader/Margin/VBox/RuleHint
@onready var matchup_panel: PanelContainer = $MatchupPanel
@onready var matchup_label: Label = $MatchupPanel/Margin/Matchup
@onready var message_panel: PanelContainer = $CombatFeed
@onready var message_label: Label = $CombatFeed/Margin/VBox/Message
@onready var bond_panel: BondEncounterPanel = $BondEncounterPanel

func _ready() -> void:
    command_menu.command_requested.connect(_on_command_requested)
    action_picker.move_selected.connect(_on_move_selected)
    action_picker.switch_selected.connect(_on_switch_selected)
    action_picker.item_selected.connect(_on_item_selected)
    action_picker.canceled.connect(_on_picker_canceled)
    bond_panel.standard_attempt_requested.connect(_on_bond_standard_requested)
    bond_panel.paid_retry_requested.connect(_on_bond_retry_requested)
    bond_panel.close_requested.connect(_on_bond_panel_closed)
    LungSaUIStyle.apply_battle_panel(encounter_panel, LungSaUIStyle.COLOR_ACCENT, false)
    LungSaUIStyle.apply_battle_panel(message_panel, LungSaUIStyle.COLOR_BORDER, false)
    LungSaUIStyle.apply_battle_panel(matchup_panel, LungSaUIStyle.COLOR_ACCENT, false)
    LungSaUIStyle.apply_kicker(encounter_label)
    LungSaUIStyle.apply_title(phase_label, 16)
    LungSaUIStyle.apply_muted(rule_hint, 9)
    LungSaUIStyle.apply_kicker($CombatFeed/Margin/VBox/Title)
    LungSaUIStyle.apply_muted(message_label, 12)
    LungSaUIStyle.apply_muted(matchup_label, 11)
    rule_hint.text = "ATTACK > SPEED > GUARD > ATTACK"

func bind_inventory(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> void:
    action_picker.bind_inventory(inventory, hotbar)

func bind_model(model: BattleStateModel) -> void:
    if battle_model != null:
        var refresh_callable: Callable = Callable(self, "_refresh")
        var phase_callable: Callable = Callable(self, "_on_phase_changed")
        if battle_model.is_connected(&"state_changed", refresh_callable):
            battle_model.disconnect(&"state_changed", refresh_callable)
        if battle_model.is_connected(&"phase_changed", phase_callable):
            battle_model.disconnect(&"phase_changed", phase_callable)

    battle_model = model
    action_picker.bind_model(battle_model)
    if battle_model != null:
        battle_model.state_changed.connect(_refresh)
        battle_model.phase_changed.connect(_on_phase_changed)
    _refresh()

func set_message(message: String) -> void:
    message_label.text = _compact_message(message)

func _refresh() -> void:
    if battle_model == null:
        opponent_status.bind_creature(null)
        player_status.bind_creature(null)
        opponent_party.bind_team(null)
        player_party.bind_team(null)
        encounter_label.text = "BATTLE"
        phase_label.text = "No active encounter"
        message_label.text = "Battle state has not been assigned."
        matchup_label.text = "Matchup unavailable"
        command_menu.bind_state(null)
        action_picker.bind_model(null)
        return

    opponent_status.bind_creature(battle_model.get_opponent_active())
    player_status.bind_creature(battle_model.get_player_active())
    opponent_party.bind_team(battle_model.opponent_team)
    player_party.bind_team(battle_model.player_team)
    encounter_label.text = _encounter_title()
    phase_label.text = "ROUND %d  •  %s" % [battle_model.round_number, _phase_display_name(battle_model.phase).to_upper()]
    command_menu.bind_state(battle_model)
    action_picker.bind_model(battle_model)
    _refresh_matchup_hint()

    if not battle_model.can_accept_player_command():
        action_picker.close_picker()
        if bond_panel.visible:
            bond_panel.close_panel()
        command_menu.visible = true

func _on_phase_changed(_previous_phase: StringName, current_phase: StringName) -> void:
    phase_label.text = "ROUND %d  •  %s" % [0 if battle_model == null else battle_model.round_number, _phase_display_name(current_phase).to_upper()]
    if current_phase == BattleStateModel.PHASE_AWAITING_PLAYER_COMMAND:
        message_label.text = "Choose an action."
    elif current_phase == BattleStateModel.PHASE_RESOLVING:
        message_label.text = "Resolving the round..."
    elif current_phase == BattleStateModel.PHASE_VICTORY:
        message_label.text = "Victory."
    elif current_phase == BattleStateModel.PHASE_DEFEAT:
        message_label.text = "Defeat."
    elif current_phase == BattleStateModel.PHASE_ESCAPED:
        message_label.text = "Escaped."

func _on_command_requested(command_type: StringName) -> void:
    if battle_model == null or not battle_model.can_accept_player_command():
        return

    if command_type == BattleStateModel.COMMAND_MOVES:
        action_picker.open_moves()
        command_menu.visible = false
        return
    if command_type == BattleStateModel.COMMAND_SWITCH:
        action_picker.open_switch()
        command_menu.visible = false
        return
    if command_type == BattleStateModel.COMMAND_ITEM:
        action_picker.open_items()
        command_menu.visible = false
        return
    command_requested.emit(command_type)

func open_bond_panel(info: Dictionary) -> void:
    if not bool(info.get("available", false)):
        set_message("Bond is not available for this encounter.")
        return
    var display_name: String = str(info.get("display_name", "Creature"))
    var chance: float = float(info.get("chance", 0.0))
    var currency: int = int(info.get("currency", 0))
    var retry_cost: int = int(info.get("retry_cost", BondRules.DEFAULT_RETRY_COST))
    var max_paid_retries: int = int(info.get("max_paid_retries", 1))
    var retry_available: bool = bool(info.get("paid_retry_available", false))
    command_menu.visible = false
    bond_panel.open_encounter(display_name, chance, currency, retry_cost, max_paid_retries)
    if bool(info.get("standard_used", false)):
        bond_panel.show_failed(currency, retry_cost, retry_available)

func close_bond_panel() -> void:
    if bond_panel.visible:
        bond_panel.close_panel()
    command_menu.visible = true
    command_menu.bind_state(battle_model)

func _on_bond_standard_requested() -> void:
    bond_attempt_requested.emit(false)

func _on_bond_retry_requested() -> void:
    bond_attempt_requested.emit(true)

func _on_bond_panel_closed() -> void:
    command_menu.visible = true
    command_menu.bind_state(battle_model)

func _on_move_selected(move_id: StringName) -> void:
    command_menu.visible = true
    move_selected.emit(move_id)

func _on_switch_selected(index: int) -> void:
    command_menu.visible = true
    switch_selected.emit(index)

func _on_item_selected(item_id: StringName, target_index: int) -> void:
    command_menu.visible = true
    item_selected.emit(item_id, target_index)

func _on_picker_canceled() -> void:
    command_menu.visible = true
    command_menu.bind_state(battle_model)

func _encounter_title() -> String:
    if battle_model == null:
        return "BATTLE"
    var kind: String = String(battle_model.encounter_kind).replace("_", " ").to_upper()
    var environment: String = String(battle_model.environment_id).replace("_", " ").replace(".", " ").capitalize()
    if environment.is_empty():
        return "%s ENCOUNTER" % kind
    return "%s  •  %s" % [kind, environment]

func _phase_display_name(phase_value: StringName) -> String:
    if phase_value == BattleStateModel.PHASE_AWAITING_PLAYER_COMMAND:
        return "Your Turn"
    if phase_value == BattleStateModel.PHASE_AWAITING_OPPONENT_COMMAND:
        return "Opponent"
    if phase_value == BattleStateModel.PHASE_RESOLVING:
        return "Resolving"
    return String(phase_value).replace("_", " ").capitalize()

func _compact_message(message: String) -> String:
    var lines: PackedStringArray = message.split("\n", false)
    if lines.size() <= 4:
        return message
    var compact: Array[String] = []
    var start_index: int = maxi(lines.size() - 4, 0)
    for index: int in range(start_index, lines.size()):
        compact.append(lines[index])
    return "\n".join(compact)

func _refresh_matchup_hint() -> void:
    if matchup_label == null or battle_model == null:
        return
    var player: BattleCreatureState = battle_model.get_player_active()
    var opponent: BattleCreatureState = battle_model.get_opponent_active()
    if player == null or opponent == null:
        matchup_label.text = "Matchup unavailable"
        return
    var relation: int = _archetype_relation(player.archetype, opponent.archetype)
    var player_name: String = String(player.archetype).to_upper()
    var opponent_name: String = String(opponent.archetype).to_upper()
    if relation > 0:
        matchup_label.text = "%s > %s  •  YOUR ADVANTAGE" % [player_name, opponent_name]
    elif relation < 0:
        matchup_label.text = "%s < %s  •  WILD ADVANTAGE" % [player_name, opponent_name]
    else:
        matchup_label.text = "%s = %s  •  EVEN MATCHUP" % [player_name, opponent_name]

func _archetype_relation(attacker: StringName, defender: StringName) -> int:
    if attacker == defender:
        return 0
    if (attacker == &"attack" and defender == &"speed") or (attacker == &"speed" and defender == &"guard") or (attacker == &"guard" and defender == &"attack"):
        return 1
    return -1
