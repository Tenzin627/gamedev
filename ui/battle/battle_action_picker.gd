extends PanelContainer
class_name BattleActionPicker

signal move_selected(move_id: StringName)
signal switch_selected(index: int)
signal item_selected(item_id: StringName, target_index: int)
signal canceled

const MODE_NONE: StringName = &"none"
const MODE_MOVES: StringName = &"moves"
const MODE_SWITCH: StringName = &"switch"
const MODE_ITEMS: StringName = &"items"

var battle_model: BattleStateModel
var mode: StringName = MODE_NONE
var battle_inventory: InventoryComponent
var battle_hotbar: HotbarComponent

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/Subtitle
@onready var options_grid: GridContainer = $Margin/VBox/OptionsScroll/OptionsGrid
@onready var cancel_button: Button = $Margin/VBox/Footer/Cancel
@onready var footer_hint: Label = $Margin/VBox/Footer/Hint

func _ready() -> void:
    LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_ACCENT, true)
    LungSaUIStyle.apply_section_title(title_label, 19)
    LungSaUIStyle.apply_muted(subtitle_label, 12)
    LungSaUIStyle.apply_muted(footer_hint, 11)
    LungSaUIStyle.apply_battle_button(cancel_button, LungSaUIStyle.COLOR_BORDER)
    cancel_button.pressed.connect(_cancel)
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed(&"ui_cancel"):
        _cancel()
        _mark_input_handled()

func bind_model(model: BattleStateModel) -> void:
    battle_model = model
    if visible:
        _rebuild()

func bind_inventory(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> void:
    battle_inventory = inventory
    battle_hotbar = hotbar
    if visible and mode == MODE_ITEMS:
        _rebuild()

func open_moves() -> void:
    mode = MODE_MOVES
    _show_picker()

func open_switch() -> void:
    mode = MODE_SWITCH
    _show_picker()

func open_items() -> void:
    mode = MODE_ITEMS
    _show_picker()

func close_picker() -> void:
    visible = false
    mode = MODE_NONE
    _clear_options()

func _show_picker() -> void:
    visible = true
    modulate = Color(1.0, 1.0, 1.0, 0.0)
    _rebuild()
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func _rebuild() -> void:
    _clear_options()
    if battle_model == null or battle_model.player_team == null:
        close_picker()
        return

    if mode == MODE_MOVES:
        title_label.text = "Choose Move"
        subtitle_label.text = "Your active creature's equipped techniques"
        footer_hint.text = "Advantage: Attack > Speed > Guard > Attack"
        _build_moves()
    elif mode == MODE_SWITCH:
        title_label.text = "Switch Creature"
        subtitle_label.text = "Choose a healthy party member"
        footer_hint.text = "Manual switching starts the switch cooldown"
        _build_switches()
    elif mode == MODE_ITEMS:
        title_label.text = "Battle Item"
        subtitle_label.text = "Use a carried item on your party"
        footer_hint.text = "Items are consumed from your normal Inventory"
        _build_items()

    var first_button: Button = _get_first_enabled_button()
    if first_button != null:
        first_button.grab_focus()
    else:
        cancel_button.grab_focus()

func _build_moves() -> void:
    var active: BattleCreatureState = battle_model.get_player_active()
    if active == null:
        _add_disabled_row("No active creature")
        return

    for move_id: StringName in active.equipped_move_ids:
        var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
        if move_definition == null:
            continue
        var button: Button = Button.new()
        var details: Array[String] = []
        details.append(move_definition.role.to_upper())
        if move_definition.power > 0:
            details.append("PWR %d" % move_definition.power)
        if move_definition.priority != 0:
            details.append("PRI %+d" % move_definition.priority)
        button.text = "%s\n%s" % [move_definition.display_name, "  •  ".join(details)]
        button.focus_mode = Control.FOCUS_ALL
        LungSaUIStyle.apply_battle_choice_button(button, LungSaUIStyle.get_role_color(move_definition.role))
        button.pressed.connect(_choose_move.bind(move_id))
        options_grid.add_child(button)

    if options_grid.get_child_count() == 0:
        _add_disabled_row("No equipped moves")

func _build_switches() -> void:
    var team: BattleTeamState = battle_model.player_team
    for index: int in range(team.creatures.size()):
        var creature: BattleCreatureState = team.creatures[index]
        if creature == null:
            continue
        var button: Button = Button.new()
        var state_text: String = "ACTIVE" if index == team.active_index else "%d/%d HP" % [creature.current_hp, creature.max_hp]
        button.text = "%s\n%s  •  %s" % [creature.display_name, String(creature.archetype).to_upper(), state_text]
        button.focus_mode = Control.FOCUS_ALL
        button.disabled = index == team.active_index or creature.is_fainted() or team.switch_cooldown_turns_remaining > 0
        LungSaUIStyle.apply_battle_choice_button(button, LungSaUIStyle.get_archetype_color(creature.archetype))
        button.pressed.connect(_choose_switch.bind(index))
        options_grid.add_child(button)

    if team.switch_cooldown_turns_remaining > 0:
        _add_disabled_row("Switch cooldown: %d turn" % team.switch_cooldown_turns_remaining)

func _build_items() -> void:
    if battle_inventory == null:
        _add_disabled_row("No inventory bound")
        return

    var added: Dictionary = {}
    for item_id: StringName in CarriedInventoryService.get_item_ids(battle_inventory, battle_hotbar):
        if item_id == &"" or added.has(item_id):
            continue
        var definition: BattleConsumableDefinition = ContentDB.get_definition(item_id) as BattleConsumableDefinition
        if definition == null or not definition.usable_in_battle:
            continue
        added[item_id] = true
        var quantity: int = CarriedInventoryService.get_total_quantity(battle_inventory, item_id, battle_hotbar)
        var button: Button = Button.new()
        button.text = "%s\n×%d  •  %s" % [definition.display_name, quantity, definition.target_mode]
        button.focus_mode = Control.FOCUS_ALL
        LungSaUIStyle.apply_battle_choice_button(button, LungSaUIStyle.COLOR_HEAL)
        button.pressed.connect(_choose_item.bind(item_id))
        options_grid.add_child(button)

    if added.is_empty():
        _add_disabled_row("No usable battle items")

func _choose_item(item_id: StringName) -> void:
    var definition: BattleConsumableDefinition = ContentDB.get_definition(item_id) as BattleConsumableDefinition
    if definition == null:
        return
    if definition.target_mode == "ActiveAlly":
        var active_index: int = 0 if battle_model == null or battle_model.player_team == null else battle_model.player_team.active_index
        close_picker()
        item_selected.emit(item_id, active_index)
        return
    _build_item_target_picker(item_id)

func _build_item_target_picker(item_id: StringName) -> void:
    _clear_options()
    title_label.text = "Choose Target"
    subtitle_label.text = "Select a creature to receive the item"
    footer_hint.text = "Fainted creatures cannot be targeted by current items"
    if battle_model == null or battle_model.player_team == null:
        _add_disabled_row("No party available")
        return

    for index: int in range(battle_model.player_team.creatures.size()):
        var creature: BattleCreatureState = battle_model.player_team.creatures[index]
        if creature == null:
            continue
        var button: Button = Button.new()
        button.text = "%s\n%d / %d HP  •  %s" % [creature.display_name, creature.current_hp, creature.max_hp, String(creature.archetype).to_upper()]
        button.disabled = creature.is_fainted()
        button.focus_mode = Control.FOCUS_ALL
        LungSaUIStyle.apply_battle_choice_button(button, LungSaUIStyle.get_archetype_color(creature.archetype))
        button.pressed.connect(_choose_item_target.bind(item_id, index))
        options_grid.add_child(button)

    var first_button: Button = _get_first_enabled_button()
    if first_button != null:
        first_button.grab_focus()

func _choose_item_target(item_id: StringName, index: int) -> void:
    close_picker()
    item_selected.emit(item_id, index)

func _choose_move(move_id: StringName) -> void:
    close_picker()
    move_selected.emit(move_id)

func _choose_switch(index: int) -> void:
    close_picker()
    switch_selected.emit(index)

func _cancel() -> void:
    close_picker()
    canceled.emit()

func _clear_options() -> void:
    for child: Node in options_grid.get_children():
        options_grid.remove_child(child)
        child.queue_free()

func _add_disabled_row(text_value: String) -> void:
    var label: Label = Label.new()
    label.custom_minimum_size = Vector2(246.0, 58.0)
    label.text = text_value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_MUTED)
    options_grid.add_child(label)

func _get_first_enabled_button() -> Button:
    for child: Node in options_grid.get_children():
        if child is Button:
            var button: Button = child as Button
            if not button.disabled:
                return button
    return null

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
