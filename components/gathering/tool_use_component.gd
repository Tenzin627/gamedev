extends Node
class_name ToolUseComponent

signal tool_use_succeeded(tool: ToolDefinition, target: ToolTargetComponent)
signal tool_use_missed(tool: ToolDefinition)
signal tool_use_failed(reason: StringName)

@export var actor_path: NodePath = NodePath("..")
@export var inventory_path: NodePath = NodePath("../InventoryComponent")
@export var hotbar_path: NodePath = NodePath("../HotbarComponent")
@export var facing_source_path: NodePath = NodePath("../AnimationComponent")
@export_flags_2d_physics var target_collision_mask: int = 32
@export_range(-1.0, 1.0, 0.05) var minimum_facing_dot: float = 0.0
@export_range(1, 128, 1) var max_query_results: int = 32

var _actor: Node2D
var _inventory: InventoryComponent
var _hotbar: HotbarComponent
var _facing_source: ActorAnimationComponent
var _next_use_time_ms: int = 0

func _ready() -> void:
    _actor = get_node_or_null(actor_path) as Node2D
    _inventory = get_node_or_null(inventory_path) as InventoryComponent
    _hotbar = get_node_or_null(hotbar_path) as HotbarComponent
    _facing_source = get_node_or_null(facing_source_path) as ActorAnimationComponent
    if _actor == null:
        push_error("ToolUseComponent requires Node2D actor at %s" % actor_path)
    if _inventory == null:
        push_error("ToolUseComponent requires InventoryComponent at %s" % inventory_path)
    if _hotbar == null:
        push_error("ToolUseComponent requires HotbarComponent at %s" % hotbar_path)

func use_selected_tool() -> bool:
    if _actor == null or _inventory == null or _hotbar == null:
        tool_use_failed.emit(&"component_not_ready")
        return false

    var selected_stack: ItemStack = _hotbar.get_selected_stack()
    if selected_stack == null or selected_stack.is_empty():
        tool_use_failed.emit(&"empty_hotbar_slot")
        return false
    var selected_id: StringName = selected_stack.item_id

    var definition: ContentDefinition = ContentDB.get_definition(selected_id)
    var tool: ToolDefinition = definition as ToolDefinition
    if tool == null:
        tool_use_failed.emit(&"selected_item_not_tool")
        return false

    var now_ms: int = Time.get_ticks_msec()
    if now_ms < _next_use_time_ms:
        tool_use_failed.emit(&"cooldown")
        return false

    var cooldown_ms: int = int(round(tool.use_cooldown_seconds * 1000.0))
    _next_use_time_ms = now_ms + maxi(cooldown_ms, 0)

    var target: ToolTargetComponent = get_best_target(tool)
    if target == null:
        tool_use_missed.emit(tool)
        return false

    var success: bool = target.apply_tool(tool, _inventory, _actor)
    if not success:
        tool_use_failed.emit(&"target_rejected")
        return false
    tool_use_succeeded.emit(tool, target)
    return true

func get_selected_tool() -> ToolDefinition:
    if _hotbar == null:
        return null
    var selected_stack: ItemStack = _hotbar.get_selected_stack()
    if selected_stack == null or selected_stack.is_empty():
        return null
    return ContentDB.get_definition(selected_stack.item_id) as ToolDefinition

func get_best_target(tool: ToolDefinition) -> ToolTargetComponent:
    if tool == null or _actor == null or not _actor.is_inside_tree():
        return null

    var circle: CircleShape2D = CircleShape2D.new()
    circle.radius = tool.reach
    var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
    query.shape = circle
    query.transform = Transform2D(0.0, _actor.global_position)
    query.collision_mask = target_collision_mask
    query.collide_with_areas = true
    query.collide_with_bodies = false

    var space_state: PhysicsDirectSpaceState2D = _actor.get_world_2d().direct_space_state
    var hits: Array[Dictionary] = space_state.intersect_shape(query, max_query_results)
    var best: ToolTargetComponent = null
    var best_priority: int = -2147483648
    var best_distance_squared: float = INF
    var best_instance_id: int = 1 << 62
    var facing: Vector2 = _get_facing_vector()

    for hit: Dictionary in hits:
        var collider_value: Variant = hit.get("collider", null)
        var candidate: ToolTargetComponent = collider_value as ToolTargetComponent
        if candidate == null or not candidate.accepts_tool(tool):
            continue

        var target_position: Vector2 = candidate.get_tool_target_position()
        var offset: Vector2 = target_position - _actor.global_position
        var distance_squared: float = offset.length_squared()
        if distance_squared > tool.reach * tool.reach:
            continue
        if not offset.is_zero_approx() and facing.dot(offset.normalized()) < minimum_facing_dot:
            continue

        var candidate_priority: int = candidate.get_tool_target_priority()
        var candidate_instance_id: int = candidate.get_instance_id()
        var is_better: bool = false
        if candidate_priority > best_priority:
            is_better = true
        elif candidate_priority == best_priority and distance_squared < best_distance_squared:
            is_better = true
        elif candidate_priority == best_priority and is_equal_approx(distance_squared, best_distance_squared) and candidate_instance_id < best_instance_id:
            is_better = true

        if is_better:
            best = candidate
            best_priority = candidate_priority
            best_distance_squared = distance_squared
            best_instance_id = candidate_instance_id

    return best

func _get_facing_vector() -> Vector2:
    if _facing_source != null and not _facing_source.facing_vector.is_zero_approx():
        return _facing_source.facing_vector.normalized()
    return Vector2.DOWN
