extends PanelContainer
class_name BattleCommandMenu

signal command_requested(command_type: StringName)

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var state_hint: Label = $Margin/VBox/Header/StateHint
@onready var moves_button: Button = $Margin/VBox/Grid/Moves
@onready var item_button: Button = $Margin/VBox/Grid/Item
@onready var switch_button: Button = $Margin/VBox/Grid/Switch
@onready var escape_button: Button = $Margin/VBox/Grid/Escape
@onready var bond_button: Button = $Margin/VBox/Grid/Bond

func _ready() -> void:
    LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_ACCENT, true)
    LungSaUIStyle.apply_kicker(title_label)
    LungSaUIStyle.apply_muted(state_hint, 12)
    LungSaUIStyle.apply_battle_button(moves_button, LungSaUIStyle.COLOR_ACCENT, true)
    LungSaUIStyle.apply_battle_button(item_button, LungSaUIStyle.COLOR_HEAL)
    LungSaUIStyle.apply_battle_button(switch_button, LungSaUIStyle.COLOR_SPEED)
    LungSaUIStyle.apply_battle_button(escape_button, LungSaUIStyle.COLOR_DANGER)
    LungSaUIStyle.apply_battle_button(bond_button, LungSaUIStyle.COLOR_ACCENT, true)
    moves_button.pressed.connect(_emit_command.bind(BattleStateModel.COMMAND_MOVES))
    item_button.pressed.connect(_emit_command.bind(BattleStateModel.COMMAND_ITEM))
    switch_button.pressed.connect(_emit_command.bind(BattleStateModel.COMMAND_SWITCH))
    escape_button.pressed.connect(_emit_command.bind(BattleStateModel.COMMAND_ESCAPE))
    bond_button.pressed.connect(_emit_command.bind(BattleStateModel.COMMAND_BOND))

func bind_state(model: BattleStateModel) -> void:
    var enabled: bool = model != null and model.can_accept_player_command()
    var ruleset: BattleRulesetDefinition = null if model == null else model.get_ruleset()

    moves_button.disabled = not enabled
    var can_switch: bool = enabled and model != null and model.player_team != null and model.player_team.creatures.size() > 1 and model.player_team.switch_cooldown_turns_remaining <= 0
    switch_button.disabled = not can_switch
    item_button.disabled = not enabled or (ruleset != null and not ruleset.allow_items)
    escape_button.disabled = not enabled or (ruleset != null and not ruleset.allow_escape)
    bond_button.visible = model != null and model.encounter_kind == &"wild"
    var bond_retry_cap: int = 1
    var bond_spell: BondSpellDefinition = ContentDB.get_definition(&"spell.bond") as BondSpellDefinition
    if bond_spell != null:
        bond_retry_cap = maxi(bond_spell.max_paid_retries_per_encounter, 0)
    var bond_exhausted: bool = model != null and model.bond_standard_attempt_used and model.bond_paid_attempts >= bond_retry_cap
    bond_button.disabled = not enabled or bond_exhausted

    moves_button.text = "MOVES\nChoose technique"
    item_button.text = "ITEM\nUse supplies"
    escape_button.text = "ESCAPE\nLeave encounter"
    if model != null and model.bond_standard_attempt_used:
        if model.bond_paid_attempts >= bond_retry_cap:
            bond_button.text = "BOND\nNo attempts remain"
        else:
            bond_button.text = "BOND\nTempt Fate once"
    else:
        bond_button.text = "BOND\nConnect with creature"
    if model != null and model.player_team != null and model.player_team.switch_cooldown_turns_remaining > 0:
        switch_button.text = "SWITCH\nCooldown %d" % model.player_team.switch_cooldown_turns_remaining
    else:
        switch_button.text = "SWITCH\nChange creature"

    if enabled:
        state_hint.text = "Choose one action"
    else:
        state_hint.text = "Turn resolving"

    if enabled and not moves_button.disabled:
        moves_button.grab_focus()

func _emit_command(command_type: StringName) -> void:
    command_requested.emit(command_type)
