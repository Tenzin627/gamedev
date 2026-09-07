extends Sprite2D

@export var animation_component_path: NodePath = NodePath("../../AnimationComponent")
@export var texture_n: Texture2D
@export var texture_s: Texture2D
@export var texture_w: Texture2D
@export var texture_e: Texture2D

var _state: StringName = &"idle"
var _facing: StringName = &"s"
var _time: float = 0.0
var _base_position: Vector2
var _animation_component: ActorAnimationComponent

func _ready() -> void:
    _base_position = position
    var candidate: Node = get_node_or_null(animation_component_path)
    if candidate is ActorAnimationComponent:
        _animation_component = candidate as ActorAnimationComponent
        _state = _animation_component.current_state
        _facing = _animation_component.facing
        _animation_component.animation_state_changed.connect(_on_animation_state_changed)
    _refresh_texture()

func _process(delta: float) -> void:
    _time += delta
    var walking: bool = _state == &"walk"
    position = _base_position + Vector2(0.0, sin(_time * 12.0) * 2.0 if walking else 0.0)
    rotation = sin(_time * 12.0) * 0.025 if walking else 0.0

func _on_animation_state_changed(state: StringName, facing: StringName, _facing_vector: Vector2) -> void:
    _state = state
    _facing = facing
    _refresh_texture()

func _refresh_texture() -> void:
    match _facing:
        &"n": texture = texture_n
        &"w": texture = texture_w
        &"e": texture = texture_e
        _: texture = texture_s
