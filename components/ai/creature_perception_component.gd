extends Node
class_name CreaturePerceptionComponent

@export var target_group: StringName = &"player"
@export_range(16.0, 1024.0, 1.0) var maximum_radius: float = 256.0
@export_range(0.05, 2.0, 0.05) var refresh_interval: float = 0.20

var body: Node2D = null
var _nearest_target: Node2D = null
var _nearest_distance: float = INF
var _remaining_refresh: float = 0.0

func configure(value_body: Node2D) -> void:
    body = value_body
    _remaining_refresh = 0.0
    refresh_now()

func process_step(delta: float) -> void:
    _remaining_refresh -= delta
    if _remaining_refresh <= 0.0:
        refresh_now()

func refresh_now() -> void:
    _remaining_refresh = refresh_interval
    _nearest_target = null
    _nearest_distance = INF
    if body == null or not body.is_inside_tree():
        return
    var tree: SceneTree = body.get_tree()
    if tree == null:
        return
    for candidate_node: Node in tree.get_nodes_in_group(target_group):
        var candidate: Node2D = candidate_node as Node2D
        if candidate == null or candidate == body or not is_instance_valid(candidate):
            continue
        var distance: float = body.global_position.distance_to(candidate.global_position)
        if distance <= maximum_radius and distance < _nearest_distance:
            _nearest_target = candidate
            _nearest_distance = distance

func get_nearest_target() -> Node2D:
    if _nearest_target != null and not is_instance_valid(_nearest_target):
        _nearest_target = null
        _nearest_distance = INF
    return _nearest_target

func get_nearest_target_distance() -> float:
    if get_nearest_target() == null:
        return INF
    return _nearest_distance
