extends CanvasLayer
class_name FarmStoragePanel

signal closed

const ITEM_SLOT_SCENE: PackedScene = preload("res://ui/shared/item_slot.tscn")

@onready var _shade: ColorRect = $Shade
@onready var _panel: PanelContainer = $Panel
var _storage: FarmStorageSystem = null
var _inventory: InventoryComponent = null
@onready var _storage_grid: GridContainer = $Panel/Margin/Content/Columns/StorageFrame/Margin/Content/Grid
@onready var _inventory_grid: GridContainer = $Panel/Margin/Content/Columns/InventoryFrame/Margin/Content/Grid
@onready var _summary: Label = $Panel/Margin/Content/Summary
@onready var _hotbar_widget: HotbarWidget = $Panel/Margin/Content/Hotbar
var _storage_slots: Array[ItemSlotWidget] = []
var _inventory_slots: Array[ItemSlotWidget] = []
var _player: PlayerActor = null
var _hud: CoreHUD = null

func _ready() -> void:
    LungSaUIStyle.apply_panel(_panel, true)
    LungSaUIStyle.apply_kicker($Panel/Margin/Content/Kicker)
    LungSaUIStyle.apply_title($Panel/Margin/Content/Header/Title, 28)
    LungSaUIStyle.apply_button($Panel/Margin/Content/Header/CloseButton, false)
    LungSaUIStyle.apply_button($Panel/Margin/Content/Actions/StoreAllButton, false)
    LungSaUIStyle.apply_button($Panel/Margin/Content/Actions/TakeAllButton, false)
    LungSaUIStyle.apply_muted(_summary, 12)
    LungSaUIStyle.apply_muted($Panel/Margin/Content/Note, 11)
    LungSaUIStyle.apply_muted($Panel/Margin/Content/Help, 11)
    LungSaUIStyle.apply_subpanel($Panel/Margin/Content/Columns/StorageFrame)
    LungSaUIStyle.apply_subpanel($Panel/Margin/Content/Columns/InventoryFrame)
    LungSaUIStyle.apply_kicker($Panel/Margin/Content/Columns/StorageFrame/Margin/Content/Title)
    LungSaUIStyle.apply_kicker($Panel/Margin/Content/Columns/InventoryFrame/Margin/Content/Title)
    $Panel/Margin/Content/Header/CloseButton.pressed.connect(close_panel)
    $Panel/Margin/Content/Actions/StoreAllButton.pressed.connect(_store_all)
    $Panel/Margin/Content/Actions/TakeAllButton.pressed.connect(_take_all)
    _hotbar_widget.slot_transfer_completed.connect(_on_slot_transfer_completed)
    _hotbar_widget.transfer_failed.connect(_on_transfer_failed)
    _panel.visible = false
    _shade.visible = false

func open_panel(storage_system: FarmStorageSystem, player: PlayerActor) -> void:
    if storage_system == null or player == null:
        return
    _storage = storage_system
    _player = player
    _inventory = player.inventory_component
    _hotbar_widget.bind_hotbar(player.hotbar_component)
    _hotbar_widget.set_quick_transfer_target(_storage.storage)
    _resolve_hud()
    _rebuild()
    if not _storage.production_changed.is_connected(_refresh):
        _storage.production_changed.connect(_refresh)
    if not _storage.storage_changed.is_connected(_refresh):
        _storage.storage_changed.connect(_refresh)
    if _inventory != null and not _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.connect(_refresh)
    _shade.visible = true
    _panel.visible = true
    if _hud != null:
        _hud.set_external_modal_blocked(&"farm_storage", true)
    else:
        _player.set_input_enabled(false)
    _refresh()
    call_deferred("_focus_default")

func close_panel() -> void:
    if _panel == null or not _panel.visible:
        return
    _panel.visible = false
    _shade.visible = false
    if _hud != null:
        _hud.set_external_modal_blocked(&"farm_storage", false)
    elif _player != null:
        _player.set_input_enabled(true)
    _disconnect_bound_signals()
    _hotbar_widget.bind_hotbar(null)
    _hotbar_widget.set_quick_transfer_target(null)
    _storage = null
    _inventory = null
    _player = null
    _hud = null
    closed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if _panel != null and _panel.visible and event.is_action_pressed(&"ui_cancel"):
        close_panel()
        var viewport: Viewport = get_viewport()
        if viewport != null:
            viewport.set_input_as_handled()

func _resolve_hud() -> void:
    var region: RegionRoot = SceneRouter.get_current_region_root()
    _hud = region.get_node_or_null(^"CoreHUD") as CoreHUD if region != null else null

func _rebuild() -> void:
    _clear_grid(_storage_grid)
    _clear_grid(_inventory_grid)
    _storage_slots.clear()
    _inventory_slots.clear()
    if _storage != null and _storage.storage != null:
        for i: int in range(_storage.storage.get_slot_count()):
            var slot: ItemSlotWidget = ITEM_SLOT_SCENE.instantiate() as ItemSlotWidget
            slot.show_slot_number = false
            slot.set_compact(true)
            slot.bind_slot(_storage.storage, i, i + 1)
            slot.set_quick_transfer_target(_inventory)
            slot.transfer_completed.connect(_on_slot_transfer_completed)
            slot.transfer_failed.connect(_on_transfer_failed)
            _storage_grid.add_child(slot)
            _storage_slots.append(slot)
    if _inventory != null:
        for i: int in range(_inventory.get_slot_count()):
            var slot: ItemSlotWidget = ITEM_SLOT_SCENE.instantiate() as ItemSlotWidget
            slot.show_slot_number = false
            slot.set_compact(true)
            slot.bind_slot(_inventory, i, i + 1)
            slot.set_quick_transfer_target(_storage.storage if _storage != null else null)
            slot.transfer_completed.connect(_on_slot_transfer_completed)
            slot.transfer_failed.connect(_on_transfer_failed)
            _inventory_grid.add_child(slot)
            _inventory_slots.append(slot)

func _clear_grid(grid: GridContainer) -> void:
    if grid == null:
        return
    for child: Node in grid.get_children():
        child.queue_free()

func _refresh() -> void:
    if _summary != null and _storage != null:
        _summary.text = _storage.get_summary_text()
    for slot: ItemSlotWidget in _storage_slots:
        slot.refresh_from_container()
    for slot: ItemSlotWidget in _inventory_slots:
        slot.refresh_from_container()

func _focus_default() -> void:
    if not _storage_slots.is_empty():
        _storage_slots[0].grab_focus()

func _on_slot_transfer_completed(_source_container: ItemSlotContainerComponent, _source_index: int, _target_container: ItemSlotContainerComponent, _target_index: int) -> void:
    _refresh()
    if _hud != null:
        _hud.show_status_message("Item moved.", 0.8)

func _on_transfer_failed(message: String) -> void:
    if _hud != null:
        _hud.show_status_message(message, 1.2)

func _store_all() -> void:
    _transfer_all(_inventory, _storage.storage if _storage != null else null)

func _take_all() -> void:
    _transfer_all(_storage.storage if _storage != null else null, _inventory)

func _transfer_all(source: ItemSlotContainerComponent, target: ItemSlotContainerComponent) -> void:
    if source == null or target == null:
        return
    var moved_any: bool = false
    for i: int in range(source.get_slot_count()):
        while source.get_stack_at(i) != null and source.transfer_slot_to_first_available(i, target):
            moved_any = true
    _refresh()
    if _hud != null:
        _hud.show_status_message("Items moved." if moved_any else "No room for those items.", 1.2)

func _disconnect_bound_signals() -> void:
    if _storage != null:
        if _storage.production_changed.is_connected(_refresh):
            _storage.production_changed.disconnect(_refresh)
        if _storage.storage_changed.is_connected(_refresh):
            _storage.storage_changed.disconnect(_refresh)
    if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.disconnect(_refresh)
