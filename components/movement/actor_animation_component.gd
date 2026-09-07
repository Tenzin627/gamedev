extends Node
class_name ActorAnimationComponent

signal animation_state_changed(state: StringName, facing: StringName, facing_vector: Vector2)

@export var animated_sprite_path: NodePath
@export var idle_state: StringName = &"idle"
@export var walk_state: StringName = &"walk"
@export var initial_facing: StringName = &"s"

var current_state: StringName = &"idle"
var facing: StringName = &"s"
var facing_vector: Vector2 = Vector2.DOWN
var _sprite: AnimatedSprite2D

func _ready() -> void:
    current_state = idle_state
    facing = initial_facing
    facing_vector = direction_name_to_vector(facing)
    _resolve_sprite()
    _apply_animation()

func set_motion(moving: bool, direction: Vector2) -> void:
    set_state(walk_state if moving else idle_state, direction)

func set_state(state: StringName, direction: Vector2 = Vector2.ZERO) -> void:
    var changed := false
    if current_state != state:
        current_state = state
        changed = true
    if not direction.is_zero_approx():
        var new_facing := direction_to_name(direction)
        if new_facing != facing:
            facing = new_facing
            facing_vector = direction_name_to_vector(facing)
            changed = true
    if changed:
        _apply_animation()
        animation_state_changed.emit(current_state, facing, facing_vector)

func get_animation_name() -> StringName:
    return StringName("%s_%s" % [String(current_state), String(facing)])

func _resolve_sprite() -> void:
    if animated_sprite_path.is_empty():
        _sprite = null
        return
    var candidate := get_node_or_null(animated_sprite_path)
    if candidate is AnimatedSprite2D:
        _sprite = candidate as AnimatedSprite2D
    else:
        _sprite = null

func _apply_animation() -> void:
    if _sprite == null or _sprite.sprite_frames == null:
        return
    var animation_name := get_animation_name()
    if _sprite.sprite_frames.has_animation(animation_name):
        _sprite.play(animation_name)
    elif _sprite.sprite_frames.has_animation(current_state):
        _sprite.play(current_state)

static func direction_to_name(direction: Vector2) -> StringName:
    if direction.is_zero_approx():
        return &"s"
    if abs(direction.x) > abs(direction.y):
        return &"e" if direction.x > 0.0 else &"w"
    return &"s" if direction.y > 0.0 else &"n"

static func direction_name_to_vector(direction_name: StringName) -> Vector2:
    match direction_name:
        &"n":
            return Vector2.UP
        &"e":
            return Vector2.RIGHT
        &"w":
            return Vector2.LEFT
        _:
            return Vector2.DOWN
