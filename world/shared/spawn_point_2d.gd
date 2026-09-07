extends Marker2D
class_name SpawnPoint2D

@export var spawn_id: StringName = &"default"

func _ready() -> void:
    add_to_group(&"spawn_point")
