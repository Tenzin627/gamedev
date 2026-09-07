extends Node
class_name CharacterMovementComponent

signal velocity_changed(velocity: Vector2)

@export var body_path: NodePath = NodePath("..")
@export_range(1.0, 2000.0, 1.0) var max_speed: float = 220.0
@export_range(1.0, 10000.0, 1.0) var acceleration: float = 1800.0
@export_range(1.0, 10000.0, 1.0) var deceleration: float = 2200.0
@export var enabled: bool = true

var desired_direction: Vector2 = Vector2.ZERO
var _body: CharacterBody2D
var _last_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
    _resolve_body()

func set_desired_direction(direction: Vector2) -> void:
    desired_direction = direction.limit_length(1.0)

func stop() -> void:
    desired_direction = Vector2.ZERO
    if _body != null:
        _body.velocity = Vector2.ZERO
    _emit_velocity_if_changed(Vector2.ZERO)

func physics_step(delta: float) -> void:
    if not enabled:
        stop()
        return
    if _body == null:
        _resolve_body()
    if _body == null:
        return

    var target_velocity := desired_direction * max_speed
    var rate := acceleration if not desired_direction.is_zero_approx() else deceleration
    _body.velocity = _body.velocity.move_toward(target_velocity, rate * delta)
    _body.move_and_slide()
    _emit_velocity_if_changed(_body.velocity)

func get_velocity() -> Vector2:
    return _body.velocity if _body != null else Vector2.ZERO

func is_moving() -> bool:
    return not get_velocity().is_zero_approx()

func _resolve_body() -> void:
    var candidate := get_node_or_null(body_path)
    if candidate is CharacterBody2D:
        _body = candidate as CharacterBody2D
    else:
        _body = null
        push_error("CharacterMovementComponent requires CharacterBody2D at body_path=%s" % body_path)

func _emit_velocity_if_changed(value: Vector2) -> void:
    if not value.is_equal_approx(_last_velocity):
        _last_velocity = value
        velocity_changed.emit(value)
