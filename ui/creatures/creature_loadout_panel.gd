extends PanelContainer
class_name CreatureLoadoutPanel

signal panel_state_changed(is_open: bool)
signal status_message_requested(message: String)
signal back_requested

@onready var title_label: Label = $Margin/VBox/Title
@onready var summary_label: Label = $Margin/VBox/Summary
@onready var trait_box: VBoxContainer = $Margin/VBox/Scroll/Content/TraitSection/TraitList
@onready var equipped_box: VBoxContainer = $Margin/VBox/Scroll/Content/MoveSection/EquippedList
@onready var learned_box: VBoxContainer = $Margin/VBox/Scroll/Content/MoveSection/LearnedList
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton
@onready var close_button: Button = $Margin/VBox/Buttons/CloseButton

var _model: CreatureCollectionModel = CreatureCollectionModel.new()
var _instance_id: String = ""

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 28)
    LungSaUIStyle.apply_muted(summary_label, 12)
    LungSaUIStyle.apply_section_title($Margin/VBox/Scroll/Content/TraitSection/Heading, 18)
    LungSaUIStyle.apply_section_title($Margin/VBox/Scroll/Content/MoveSection/EquippedHeading, 18)
    LungSaUIStyle.apply_section_title($Margin/VBox/Scroll/Content/MoveSection/LearnedHeading, 18)
    LungSaUIStyle.apply_muted($Margin/VBox/Hint, 11)
    LungSaUIStyle.apply_button(back_button, false)
    LungSaUIStyle.apply_button(close_button, false)
    back_button.pressed.connect(_on_back_pressed)
    close_button.pressed.connect(close_panel)
    if not GameSession.creature_collection_changed.is_connected(_refresh):
        GameSession.creature_collection_changed.connect(_refresh)
    visible = false

func _exit_tree() -> void:
    if GameSession.creature_collection_changed.is_connected(_refresh):
        GameSession.creature_collection_changed.disconnect(_refresh)

func open_for_creature(instance_id: String) -> void:
    _instance_id = instance_id
    _refresh()
    visible = true
    panel_state_changed.emit(true)
    back_button.grab_focus()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    _instance_id = ""
    panel_state_changed.emit(false)

func _refresh() -> void:
    if not is_inside_tree() or _instance_id.is_empty():
        return
    var creature: CreatureInstanceData = _model.get_creature(_instance_id)
    if creature == null:
        close_panel()
        return
    title_label.text = "%s — Loadout" % CreatureDetailPresentationModel.get_creature_name(creature)
    summary_label.text = CreatureDetailPresentationModel.get_summary(creature)
    _clear_box(trait_box)
    _clear_box(equipped_box)
    _clear_box(learned_box)
    _build_traits(creature)
    _build_equipped_moves(creature)
    _build_learned_moves(creature)

func _build_traits(creature: CreatureInstanceData) -> void:
    if creature.trait_candidate_ids.is_empty():
        var empty_label: Label = Label.new()
        empty_label.text = "No trait candidates are available for this creature."
        LungSaUIStyle.apply_muted(empty_label, 12)
        trait_box.add_child(empty_label)
        return
    for trait_id: StringName in creature.trait_candidate_ids:
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        var label: Label = Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var active_text: String = "ACTIVE • " if creature.active_trait_id == trait_id else ""
        label.text = "%s%s\n%s" % [active_text, CreatureDetailPresentationModel.get_trait_name(trait_id), CreatureDetailPresentationModel.get_trait_description(trait_id)]
        row.add_child(label)
        var select_button: Button = Button.new()
        select_button.text = "Active" if creature.active_trait_id == trait_id else "Select"
        select_button.disabled = creature.active_trait_id == trait_id
        LungSaUIStyle.apply_button(select_button, creature.active_trait_id != trait_id)
        select_button.pressed.connect(_select_trait.bind(trait_id))
        row.add_child(select_button)
        trait_box.add_child(row)

func _build_equipped_moves(creature: CreatureInstanceData) -> void:
    if creature.equipped_move_ids.is_empty():
        var empty_label: Label = Label.new()
        empty_label.text = "No moves equipped. Equip up to %d learned moves." % CreatureCollectionModel.EQUIPPED_MOVE_LIMIT
        LungSaUIStyle.apply_muted(empty_label, 12)
        equipped_box.add_child(empty_label)
        return
    for index: int in range(creature.equipped_move_ids.size()):
        var move_id: StringName = creature.equipped_move_ids[index]
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var label: Label = Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "%d. %s\n%s" % [index + 1, CreatureDetailPresentationModel.get_move_name(move_id), CreatureDetailPresentationModel.get_move_description(move_id)]
        row.add_child(label)
        var up_button: Button = Button.new()
        up_button.text = "↑"
        up_button.tooltip_text = "Move up"
        up_button.disabled = index <= 0
        LungSaUIStyle.apply_button(up_button, false)
        up_button.custom_minimum_size = Vector2(44.0, 44.0)
        up_button.pressed.connect(_move_equipped.bind(index, index - 1))
        row.add_child(up_button)
        var down_button: Button = Button.new()
        down_button.text = "↓"
        down_button.tooltip_text = "Move down"
        down_button.disabled = index >= creature.equipped_move_ids.size() - 1
        LungSaUIStyle.apply_button(down_button, false)
        down_button.custom_minimum_size = Vector2(44.0, 44.0)
        down_button.pressed.connect(_move_equipped.bind(index, index + 1))
        row.add_child(down_button)
        var remove_button: Button = Button.new()
        remove_button.text = "Unequip"
        LungSaUIStyle.apply_button(remove_button, false)
        remove_button.pressed.connect(_unequip_move.bind(move_id))
        row.add_child(remove_button)
        equipped_box.add_child(row)

func _build_learned_moves(creature: CreatureInstanceData) -> void:
    if creature.learned_move_ids.is_empty():
        var empty_label: Label = Label.new()
        empty_label.text = "No learned moves yet."
        LungSaUIStyle.apply_muted(empty_label, 12)
        learned_box.add_child(empty_label)
        return
    for move_id: StringName in creature.learned_move_ids:
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        var label: Label = Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "%s\n%s" % [CreatureDetailPresentationModel.get_move_name(move_id), CreatureDetailPresentationModel.get_move_description(move_id)]
        row.add_child(label)
        var equipped: bool = creature.equipped_move_ids.has(move_id)
        var equip_button: Button = Button.new()
        equip_button.text = "Equipped" if equipped else "Equip"
        equip_button.disabled = equipped or creature.equipped_move_ids.size() >= CreatureCollectionModel.EQUIPPED_MOVE_LIMIT
        LungSaUIStyle.apply_button(equip_button, not equip_button.disabled)
        equip_button.pressed.connect(_equip_move.bind(move_id))
        row.add_child(equip_button)
        learned_box.add_child(row)

func _select_trait(trait_id: StringName) -> void:
    _emit_result(_model.set_active_trait(_instance_id, trait_id))

func _equip_move(move_id: StringName) -> void:
    _emit_result(_model.equip_move(_instance_id, move_id))

func _unequip_move(move_id: StringName) -> void:
    _emit_result(_model.unequip_move(_instance_id, move_id))

func _move_equipped(from_index: int, to_index: int) -> void:
    _emit_result(_model.move_equipped_move(_instance_id, from_index, to_index))

func _emit_result(result: Dictionary) -> void:
    status_message_requested.emit(str(result.get("message", "Loadout updated.")))
    _refresh()

func _on_back_pressed() -> void:
    close_panel()
    back_requested.emit()

func _clear_box(box: VBoxContainer) -> void:
    for child: Node in box.get_children():
        child.queue_free()
