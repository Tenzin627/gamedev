extends ItemSlotContainerComponent
class_name StorageContainerComponent

signal storage_changed

@export_range(1, 200, 1) var slot_capacity: int = 12

func _ready() -> void:
    configure_slots(slot_capacity)
    if not container_changed.is_connected(_on_container_changed):
        container_changed.connect(_on_container_changed)

func export_state() -> Dictionary:
    return {
        "slot_capacity": slot_capacity,
        "slots": export_slots(),
    }

func import_state(data: Dictionary) -> void:
    slot_capacity = maxi(int(data.get("slot_capacity", slot_capacity)), 1)
    import_slots(Array(data.get("slots", [])), slot_capacity)

func _on_container_changed() -> void:
    storage_changed.emit()
