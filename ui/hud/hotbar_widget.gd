extends PanelContainer
class_name HotbarWidget

signal tooltip_requested(title: String, body: String, anchor_rect: Rect2)
signal tooltip_hidden
signal slot_transfer_completed(source_container: ItemSlotContainerComponent, source_index: int, target_container: ItemSlotContainerComponent, target_index: int)
signal transfer_failed(message: String)

const ITEM_SLOT_SCENE: PackedScene = preload("res://ui/shared/item_slot.tscn")

@export var show_item_names: bool = true

var _hotbar: HotbarComponent
var _quick_transfer_target: ItemSlotContainerComponent = null
@onready var _slots_box: HBoxContainer = $Margin/Content/Slots
var _slot_widgets: Array[ItemSlotWidget] = []
@onready var _selected_label: Label = $Margin/Content/SelectedLabel

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, false)
    LungSaUIStyle.apply_muted(_selected_label, 11)
    _refresh()

func bind_hotbar(hotbar: HotbarComponent) -> void:
    if _hotbar != null:
        if _hotbar.hotbar_changed.is_connected(_refresh):
            _hotbar.hotbar_changed.disconnect(_refresh)
        if _hotbar.selection_changed.is_connected(_on_selection_changed):
            _hotbar.selection_changed.disconnect(_on_selection_changed)
    _hotbar = hotbar
    if _hotbar != null:
        if not _hotbar.hotbar_changed.is_connected(_refresh):
            _hotbar.hotbar_changed.connect(_refresh)
        if not _hotbar.selection_changed.is_connected(_on_selection_changed):
            _hotbar.selection_changed.connect(_on_selection_changed)
    _rebuild_slots()
    _refresh()

func set_quick_transfer_target(target: ItemSlotContainerComponent) -> void:
    _quick_transfer_target = target
    for slot: ItemSlotWidget in _slot_widgets:
        slot.set_quick_transfer_target(target)

func _rebuild_slots() -> void:
    if _slots_box == null:
        return
    for child: Node in _slots_box.get_children():
        child.queue_free()
    _slot_widgets.clear()

    var count: int = _hotbar.slot_count if _hotbar != null else 8
    for i: int in range(count):
        var slot: ItemSlotWidget = ITEM_SLOT_SCENE.instantiate() as ItemSlotWidget
        if slot == null:
            push_error("HotbarWidget: failed to instantiate ItemSlotWidget scene")
            continue
        slot.show_slot_number = true
        slot.set_compact(true)
        slot.bind_slot(_hotbar, i, i + 1)
        slot.set_quick_transfer_target(_quick_transfer_target)
        slot.item_activated.connect(_on_slot_activated)
        slot.tooltip_requested.connect(_on_tooltip_requested)
        slot.tooltip_hidden.connect(_on_tooltip_hidden)
        slot.transfer_completed.connect(_on_slot_transfer_completed)
        slot.transfer_failed.connect(_on_transfer_failed)
        _slots_box.add_child(slot)
        _slot_widgets.append(slot)

func _refresh() -> void:
    if _slots_box == null:
        return
    if _hotbar == null:
        if _selected_label != null:
            _selected_label.text = "QUICK BAR"
        return
    if _slot_widgets.size() != _hotbar.slot_count:
        _rebuild_slots()

    for i: int in range(mini(_slot_widgets.size(), _hotbar.slot_count)):
        var slot: ItemSlotWidget = _slot_widgets[i]
        slot.refresh_from_container()
        slot.set_selected(i == _hotbar.selected_index)

    var selected_stack: ItemStack = _hotbar.get_selected_stack()
    if selected_stack == null or selected_stack.is_empty():
        _selected_label.text = "QUICK BAR  •  SLOT %d EMPTY" % (_hotbar.selected_index + 1)
        return

    var definition: ItemDefinition = ContentDB.get_definition(selected_stack.item_id) as ItemDefinition
    var display: String = definition.display_name if definition != null else String(selected_stack.item_id)
    if show_item_names:
        _selected_label.text = "SELECTED  •  %s  ×%d  •  [F] USE" % [display.to_upper(), selected_stack.quantity]
    else:
        _selected_label.text = "SELECTED  •  SLOT %d" % (_hotbar.selected_index + 1)

func _on_slot_activated(slot_index: int, _item_id: StringName) -> void:
    if _hotbar != null:
        _hotbar.select_slot(slot_index)

func _on_selection_changed(_slot_index: int, _item_id: StringName) -> void:
    _refresh()

func _on_slot_transfer_completed(source_container: ItemSlotContainerComponent, source_index: int, target_container: ItemSlotContainerComponent, target_index: int) -> void:
    slot_transfer_completed.emit(source_container, source_index, target_container, target_index)

func _on_transfer_failed(message: String) -> void:
    transfer_failed.emit(message)

func _on_tooltip_requested(title: String, body: String, anchor_rect: Rect2) -> void:
    tooltip_requested.emit(title, body, anchor_rect)

func _on_tooltip_hidden() -> void:
    tooltip_hidden.emit()
