extends Node2D
class_name FarmCreatureWorkPresenter

@onready var animated_visual: AnimatedSprite2D = $AnimatedVisual
@onready var static_visual: Sprite2D = $StaticVisual
@onready var animation_component: ActorAnimationComponent = $AnimationComponent

var _instance_id: String = ""
var _species_id: StringName = &""
var _display_name: String = "Creature"
var _archetype: String = "Balanced"
var _target_position: Vector2 = Vector2.ZERO
var _state_text: String = "Resting"
var _progress: float = 0.0
var _species: CreatureSpeciesDefinition = null

func configure(instance_id: String, species_id: StringName, display_name: String, archetype: String) -> void:
    _instance_id = instance_id
    _species_id = species_id
    _display_name = display_name
    _archetype = archetype
    _species = ContentDB.get_definition(_species_id) as CreatureSpeciesDefinition
    if is_inside_tree():
        _apply_visual()
    queue_redraw()

func _ready() -> void:
    _apply_visual()

func set_work_state(target_position: Vector2, state_text: String, progress: float) -> void:
    _target_position = target_position
    if _state_text != state_text or not is_equal_approx(_progress, progress):
        _state_text = state_text
        _progress = progress
        queue_redraw()

func advance_presentation(delta: float, speed: float) -> void:
    var delta_to_target: Vector2 = _target_position - position
    var moving: bool = delta_to_target.length() > 12.0
    if moving:
        var direction: Vector2 = delta_to_target.normalized()
        position = position.move_toward(_target_position, speed * delta)
        if animation_component != null:
            animation_component.set_motion(true, direction)
    elif animation_component != null:
        animation_component.set_motion(false, Vector2.ZERO)
    queue_redraw()

func _apply_visual() -> void:
    if animated_visual == null or static_visual == null:
        return
    if _species == null:
        animated_visual.visible = false
        static_visual.visible = false
        return
    animated_visual.position = _species.world_visual_offset
    static_visual.position = _species.world_visual_offset
    animated_visual.scale = _species.world_visual_scale
    static_visual.scale = _species.world_visual_scale
    if _species.world_sprite_frames != null:
        animated_visual.sprite_frames = _species.world_sprite_frames
        animated_visual.visible = true
        static_visual.visible = false
        if animation_component != null:
            animation_component.set_state(&"idle", Vector2.DOWN)
    else:
        animated_visual.sprite_frames = null
        animated_visual.visible = false
        static_visual.texture = _species.world_texture
        static_visual.visible = static_visual.texture != null

func _draw() -> void:
    if _state_text == "Watering":
        draw_line(Vector2(14, 5), Vector2(27, 11), Color(0.38, 0.62, 0.78, 0.9), 3.0)
        draw_circle(Vector2(29, 14), 2.5, Color(0.48, 0.74, 0.88, 0.9))
    elif _state_text == "Harvesting" or _state_text == "Gathering Materials":
        draw_circle(Vector2(22, 7), 5.0, Color(0.83, 0.66, 0.25, 0.95))
    elif _state_text == "Carrying to Chest":
        draw_rect(Rect2(17, 4, 12, 10), Color(0.66, 0.46, 0.24, 0.95), true)
    elif _state_text == "Tilling":
        draw_line(Vector2(12, 4), Vector2(26, 15), Color(0.54, 0.39, 0.24, 0.95), 3.0)
        draw_line(Vector2(23, 13), Vector2(30, 9), Color(0.70, 0.55, 0.34, 0.95), 3.0)
    elif _state_text == "Planting":
        draw_circle(Vector2(23, 10), 3.5, Color(0.72, 0.57, 0.27, 0.95))
        draw_line(Vector2(23, 8), Vector2(25, 3), Color(0.37, 0.62, 0.30, 0.95), 2.0)
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-34, -28), _display_name, HORIZONTAL_ALIGNMENT_CENTER, 68, 11, Color(0.94, 0.93, 0.82, 1.0))
    draw_string(font, Vector2(-34, 31), _state_text, HORIZONTAL_ALIGNMENT_CENTER, 68, 10, Color(0.84, 0.87, 0.74, 1.0))
    if _state_text != "Resting" and _state_text != "Carrying to Chest":
        draw_rect(Rect2(-24, 36, 48, 4), Color(0.08, 0.09, 0.07, 0.75), true)
        draw_rect(Rect2(-24, 36, 48.0 * clampf(_progress, 0.0, 1.0), 4), Color(0.62, 0.77, 0.42, 1.0), true)
