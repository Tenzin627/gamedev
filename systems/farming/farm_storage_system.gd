extends RegionLocalSystem
class_name FarmStorageSystem

signal storage_changed
signal production_changed

@export_range(1, 200, 1) var storage_slots: int = 24
var storage: StorageContainerComponent = null
var total_auto_harvests: int = 0
var total_auto_material_runs: int = 0
var total_auto_items: int = 0
var blocked_outputs: int = 0

func _ready() -> void:
    storage = StorageContainerComponent.new()
    storage.name = "FarmStorage"
    storage.slot_capacity = storage_slots
    add_child(storage)
    if not storage.storage_changed.is_connected(_on_storage_changed):
        storage.storage_changed.connect(_on_storage_changed)

func can_store(items: Dictionary) -> bool:
    return storage != null and storage.can_add_batch(items)

func store_batch(items: Dictionary) -> bool:
    if storage == null or not storage.can_add_batch(items):
        blocked_outputs += 1
        production_changed.emit()
        return false
    var leftovers: Dictionary = storage.add_batch(items)
    if not leftovers.is_empty():
        blocked_outputs += 1
        production_changed.emit()
        return false
    return true

func record_auto_harvest(item_count: int) -> void:
    total_auto_harvests += 1
    total_auto_items += maxi(item_count, 0)
    production_changed.emit()

func record_auto_material_run(item_count: int) -> void:
    total_auto_material_runs += 1
    total_auto_items += maxi(item_count, 0)
    production_changed.emit()

func get_summary_text() -> String:
    return "Crop runs: %d  •  Material runs: %d  •  Helper items: %d  •  Blocked: %d" % [total_auto_harvests, total_auto_material_runs, total_auto_items, blocked_outputs]

func export_runtime_state() -> Dictionary:
    return {
        "storage": storage.export_state() if storage != null else {},
        "auto_harvests": total_auto_harvests,
        "auto_material_runs": total_auto_material_runs,
        "auto_items": total_auto_items,
        "blocked_outputs": blocked_outputs,
    }

func import_runtime_state(state: Dictionary) -> void:
    if storage == null:
        return
    var storage_value: Variant = state.get("storage", {})
    if storage_value is Dictionary:
        storage.import_state(Dictionary(storage_value))
    total_auto_harvests = maxi(int(state.get("auto_harvests", 0)), 0)
    total_auto_material_runs = maxi(int(state.get("auto_material_runs", 0)), 0)
    total_auto_items = maxi(int(state.get("auto_items", 0)), 0)
    blocked_outputs = maxi(int(state.get("blocked_outputs", 0)), 0)
    production_changed.emit()

func _on_storage_changed() -> void:
    storage_changed.emit()
