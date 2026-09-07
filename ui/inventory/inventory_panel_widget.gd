extends PanelContainer
class_name InventoryPanelWidget

signal close_requested
signal item_slot_activated(slot_index: int, item_id: StringName)
signal tooltip_requested(title: String, body: String, anchor_rect: Rect2)
signal tooltip_hidden
signal slot_transfer_completed(source_container: ItemSlotContainerComponent, source_index: int, target_container: ItemSlotContainerComponent, target_index: int)
signal transfer_failed(message: String)

const ITEM_SLOT_SCENE: PackedScene = preload("res://ui/shared/item_slot.tscn")

@export_range(1, 12, 1) var columns: int = 6

var _inventory: InventoryComponent
var _quick_transfer_target: ItemSlotContainerComponent = null
@onready var _grid: GridContainer = $Margin/Content/Grid
@onready var _summary_label: Label = $Margin/Content/Summary
@onready var _close_button: Button = $Margin/Content/Header/CloseButton
var _slot_widgets: Array[ItemSlotWidget] = []

func _ready() -> void:
    focus_mode = Control.FOCUS_NONE
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_kicker($Margin/Content/Kicker)
    LungSaUIStyle.apply_title($Margin/Content/Header/Title, 28)
    LungSaUIStyle.apply_muted(_summary_label, 12)
    LungSaUIStyle.apply_muted($Margin/Content/Help, 11)
    LungSaUIStyle.apply_button(_close_button, false)
    _close_button.pressed.connect(close_panel)
    _grid.columns = columns
    visible = false

func bind_inventory(inventory: InventoryComponent) -> void:
    if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.disconnect(_refresh)
    _inventory = inventory
    if _inventory != null and not _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.connect(_refresh)
    _rebuild_slots()
    _refresh()

func set_quick_transfer_target(target: ItemSlotContainerComponent) -> void:
    _quick_transfer_target = target
    for slot: ItemSlotWidget in _slot_widgets:
        slot.set_quick_transfer_target(target)

func open_panel() -> void:
    visible = true
    _refresh()
    call_deferred("_focus_default")

func close_panel() -> void:
    if not visible:
        return
    var focus_owner: Control = get_viewport().gui_get_focus_owner()
    if focus_owner != null and is_ancestor_of(focus_owner):
        focus_owner.release_focus()
    visible = false
    tooltip_hidden.emit()
    close_requested.emit()

func toggle_panel() -> void:
    if visible:
        close_panel()
    else:
        open_panel()

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed(&"ui_cancel"):
        close_panel()
        _mark_input_handled()

func _rebuild_slots() -> void:
    if _grid == null:
        return
    for child: Node in _grid.get_children():
        child.queue_free()
    _slot_widgets.clear()

    var count: int = _inventory.get_slot_count() if _inventory != null else 24
    for i: int in range(count):
        var slot: ItemSlotWidget = ITEM_SLOT_SCENE.instantiate() as ItemSlotWidget
        if slot == null:
            push_error("InventoryPanelWidget: failed to instantiate ItemSlotWidget scene")
            continue
        slot.show_slot_number = false
        slot.set_compact(false)
        slot.bind_slot(_inventory, i, i + 1)
        slot.set_quick_transfer_target(_quick_transfer_target)
        slot.item_activated.connect(_on_slot_activated)
        slot.tooltip_requested.connect(_on_tooltip_requested)
        slot.tooltip_hidden.connect(_on_tooltip_hidden)
        slot.transfer_completed.connect(_on_slot_transfer_completed)
        slot.transfer_failed.connect(_on_transfer_failed)
        _grid.add_child(slot)
        _slot_widgets.append(slot)

func _refresh() -> void:
    if _grid == null:
        return
    if _inventory == null:
        _summary_label.text = "Pack unavailable"
        return
    if _slot_widgets.size() != _inventory.get_slot_count():
        _rebuild_slots()

    var occupied: int = 0
    for i: int in range(mini(_slot_widgets.size(), _inventory.get_slot_count())):
        var stack: ItemStack = _inventory.get_stack_at(i)
        if stack != null and not stack.is_empty():
            occupied += 1
        _slot_widgets[i].refresh_from_container()
        _slot_widgets[i].set_selected(false)
    _summary_label.text = "%d / %d slots used  •  Hover or focus an item for details" % [occupied, _inventory.get_slot_count()]

func _focus_default() -> void:
    for slot: ItemSlotWidget in _slot_widgets:
        if slot.get_item_id() != &"":
            slot.grab_focus()
            return
    if not _slot_widgets.is_empty():
        _slot_widgets[0].grab_focus()
    elif _close_button != null:
        _close_button.grab_focus()

func _on_slot_activated(slot_index: int, item_id: StringName) -> void:
    item_slot_activated.emit(slot_index, item_id)

func _on_slot_transfer_completed(source_container: ItemSlotContainerComponent, source_index: int, target_container: ItemSlotContainerComponent, target_index: int) -> void:
    slot_transfer_completed.emit(source_container, source_index, target_container, target_index)

func _on_transfer_failed(message: String) -> void:
    transfer_failed.emit(message)

func _on_tooltip_requested(title: String, body: String, anchor_rect: Rect2) -> void:
    tooltip_requested.emit(title, body, anchor_rect)

func _on_tooltip_hidden() -> void:
    tooltip_hidden.emit()

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
