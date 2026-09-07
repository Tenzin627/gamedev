extends Control
class_name BattleStageCreatureWidget

var creature_state: BattleCreatureState
var facing_left: bool = false
var _animation_time: float = 0.0
var _intro_amount: float = 0.0
var _hit_flash: float = 0.0
var _last_actor_id: String = ""
var _last_hp: int = -1

@onready var name_label: Label = $Name
@onready var archetype_label: Label = $Archetype

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    _animation_time += delta
    _intro_amount = minf(_intro_amount + delta * 2.8, 1.0)
    _hit_flash = maxf(_hit_flash - delta * 3.8, 0.0)
    queue_redraw()

func bind_creature(creature: BattleCreatureState, should_face_left: bool) -> void:
    var incoming_actor_id: String = "" if creature == null else creature.battle_actor_id
    var incoming_hp: int = -1 if creature == null else creature.current_hp

    if incoming_actor_id != _last_actor_id:
        _intro_amount = 0.0
    elif _last_hp >= 0 and incoming_hp >= 0 and incoming_hp < _last_hp:
        _hit_flash = 1.0

    creature_state = creature
    facing_left = should_face_left
    _last_actor_id = incoming_actor_id
    _last_hp = incoming_hp

    if creature_state == null:
        name_label.text = ""
        archetype_label.text = ""
    else:
        name_label.text = creature_state.display_name
        archetype_label.text = String(creature_state.archetype).to_upper()
        archetype_label.add_theme_color_override(&"font_color", LungSaUIStyle.get_archetype_color(creature_state.archetype).lightened(0.18))
    queue_redraw()

func _draw() -> void:
    if creature_state == null:
        return

    var accent: Color = LungSaUIStyle.get_archetype_color(creature_state.archetype)
    var direction: float = -1.0 if facing_left else 1.0
    var idle_offset: float = sin(_animation_time * 1.7) * 4.0
    var entry_offset: float = (1.0 - _ease_out(_intro_amount)) * 38.0 * -direction
    var center: Vector2 = Vector2(size.x * 0.5 + entry_offset, size.y * 0.49 + idle_offset)
    var fainted: bool = creature_state.is_fainted()
    var alpha: float = 0.42 if fainted else 1.0

    _draw_aura(center, accent, alpha)
    _draw_shadow(center, alpha)
    _draw_creature_body(center, direction, accent, alpha)

    if _hit_flash > 0.0:
        var flash_color: Color = Color(1.0, 0.91, 0.77, _hit_flash * 0.48)
        draw_circle(center + Vector2(direction * 10.0, -16.0), 78.0 + _hit_flash * 8.0, flash_color)

func _draw_aura(center: Vector2, accent: Color, alpha: float) -> void:
    var pulse: float = 1.0 + sin(_animation_time * 1.2) * 0.035
    var ring_color: Color = accent
    ring_color.a = 0.12 * alpha
    var ring_points: PackedVector2Array = _oval_points(center + Vector2(0.0, 54.0), Vector2(92.0 * pulse, 24.0 * pulse), 34)
    if not ring_points.is_empty():
        ring_points.append(ring_points[0])
    draw_polyline(ring_points, ring_color, 3.0, true)

func _draw_shadow(center: Vector2, alpha: float) -> void:
    var shadow: Color = Color(0.02, 0.05, 0.035, 0.38 * alpha)
    draw_colored_polygon(_oval_points(center + Vector2(0.0, 72.0), Vector2(74.0, 18.0), 32), shadow)

func _draw_creature_body(center: Vector2, direction: float, _accent: Color, alpha: float) -> void:
    draw_set_transform(center, 0.0, Vector2(direction, 1))
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature_state.species_id) as CreatureSpeciesDefinition
    if species != null and species.world_texture != null:
        var creature_modulate: Color = species.world_visual_modulate
        creature_modulate.a *= alpha
        draw_texture_rect(species.world_texture, Rect2(-106, -94, 212, 184), false, creature_modulate)
    else:
        draw_circle(Vector2(0, -8), 70.0, Color(0.46, 0.61, 0.40, alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_archetype_mark(center: Vector2, archetype_value: StringName, accent: Color, alpha: float) -> void:
    var mark_color: Color = accent.lightened(0.30)
    mark_color.a = 0.78 * alpha
    if archetype_value == &"attack":
        var attack_points: PackedVector2Array = PackedVector2Array([
            center + Vector2(0.0, -13.0),
            center + Vector2(12.0, 10.0),
            center + Vector2(-12.0, 10.0),
        ])
        draw_colored_polygon(attack_points, mark_color)
        return
    if archetype_value == &"speed":
        draw_line(center + Vector2(-14.0, -7.0), center + Vector2(10.0, -7.0), mark_color, 5.0, true)
        draw_line(center + Vector2(-8.0, 2.0), center + Vector2(15.0, 2.0), mark_color, 5.0, true)
        draw_line(center + Vector2(-13.0, 11.0), center + Vector2(7.0, 11.0), mark_color, 5.0, true)
        return
    var guard_points: PackedVector2Array = PackedVector2Array([
        center + Vector2(0.0, -14.0),
        center + Vector2(12.0, -7.0),
        center + Vector2(9.0, 9.0),
        center + Vector2(0.0, 15.0),
        center + Vector2(-9.0, 9.0),
        center + Vector2(-12.0, -7.0),
    ])
    draw_colored_polygon(guard_points, mark_color)

func _oval_points(center: Vector2, radius: Vector2, segments: int) -> PackedVector2Array:
    var result: PackedVector2Array = PackedVector2Array()
    var safe_segments: int = maxi(segments, 8)
    for index: int in range(safe_segments):
        var angle: float = TAU * float(index) / float(safe_segments)
        result.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    return result

func _ease_out(value: float) -> float:
    var clamped: float = clampf(value, 0.0, 1.0)
    return 1.0 - pow(1.0 - clamped, 3.0)
