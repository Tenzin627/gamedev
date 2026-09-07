@tool
extends Area2D
class_name HabitatArea2D

signal habitat_definition_resolved(habitat_instance_id: StringName, definition: HabitatDefinition)

@export var habitat_instance_id: StringName = &""
@export var habitat_definition_id: StringName = &""
@export var area_size: Vector2 = Vector2(480.0, 300.0)
@export_range(0.0, 128.0, 1.0) var spawn_margin: float = 24.0
@export var debug_draw_enabled: bool = false
@export var show_in_editor: bool = true
@export var debug_color: Color = Color(0.55, 0.82, 0.58, 0.16)

var _definition: HabitatDefinition = null

func _enter_tree() -> void:
    _configure_collision_shape()

func _ready() -> void:
    if Engine.is_editor_hint():
        _configure_collision_shape()
        queue_redraw()
        return
    add_to_group(&"habitat_area")
    monitoring = false
    monitorable = false
    _definition = ContentDB.get_definition(habitat_definition_id) as HabitatDefinition
    if _definition == null:
        push_error("HabitatArea2D %s could not resolve %s" % [String(habitat_instance_id), String(habitat_definition_id)])
    else:
        habitat_definition_resolved.emit(habitat_instance_id, _definition)
    queue_redraw()

func get_definition() -> HabitatDefinition:
    if _definition == null:
        _definition = ContentDB.get_definition(habitat_definition_id) as HabitatDefinition
    return _definition

func get_random_spawn_position(rng: RandomNumberGenerator) -> Vector2:
    var bounds: Rect2 = get_local_spawn_rect()
    var local_x: float = rng.randf_range(bounds.position.x, bounds.end.x)
    var local_y: float = rng.randf_range(bounds.position.y, bounds.end.y)
    return to_global(Vector2(local_x, local_y))

func get_local_spawn_rect() -> Rect2:
    var safe_half_width: float = maxf((area_size.x * 0.5) - spawn_margin, 1.0)
    var safe_half_height: float = maxf((area_size.y * 0.5) - spawn_margin, 1.0)
    return Rect2(Vector2(-safe_half_width, -safe_half_height), Vector2(safe_half_width * 2.0, safe_half_height * 2.0))

func contains_global_position(world_position: Vector2) -> bool:
    return get_local_spawn_rect().has_point(to_local(world_position))

func validate_habitat_area() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if habitat_instance_id == &"":
        errors.append("HabitatArea2D is missing habitat_instance_id")
    elif not String(habitat_instance_id).begins_with("habitat_instance."):
        errors.append("HabitatArea2D instance ID should use habitat_instance.*: %s" % String(habitat_instance_id))
    if habitat_definition_id == &"":
        errors.append("HabitatArea2D %s is missing habitat_definition_id" % String(habitat_instance_id))
    elif not String(habitat_definition_id).begins_with("habitat."):
        errors.append("HabitatArea2D definition ID should use habitat.*: %s" % String(habitat_definition_id))
    if area_size.x <= 0.0 or area_size.y <= 0.0:
        errors.append("HabitatArea2D %s area_size must be positive" % String(habitat_instance_id))
    if spawn_margin * 2.0 >= minf(area_size.x, area_size.y):
        errors.append("HabitatArea2D %s spawn_margin leaves no usable spawn area" % String(habitat_instance_id))
    return errors

func _configure_collision_shape() -> void:
    var collision_shape: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
    if collision_shape == null:
        return
    var rectangle: RectangleShape2D = RectangleShape2D.new()
    rectangle.size = Vector2(maxf(area_size.x, 1.0), maxf(area_size.y, 1.0))
    collision_shape.shape = rectangle

func _draw() -> void:
    if not debug_draw_enabled and not (Engine.is_editor_hint() and show_in_editor):
        return
    var rect: Rect2 = Rect2(-area_size * 0.5, area_size)
    draw_rect(rect, debug_color, true)
    draw_rect(rect, Color(debug_color.r, debug_color.g, debug_color.b, 0.58), false, 2.0)
