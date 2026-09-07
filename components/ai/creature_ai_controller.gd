extends Node
class_name CreatureAIController

signal active_behavior_changed(previous_id: StringName, current_id: StringName)

@export var profile_id: StringName = &"ai_profile.wild.balanced"
@export var enabled: bool = true
@export var perception_path: NodePath = ^"../CreaturePerceptionComponent"
@export var behavior_container_path: NodePath = ^"Behaviors"

var body: CharacterBody2D = null
var habitat: HabitatArea2D = null
var profile: CreatureAIProfileDefinition = null
var perception: CreaturePerceptionComponent = null
var context: CreatureAIContext = CreatureAIContext.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _behaviors: Array[CreatureAIBehavior] = []
var _active_behavior: CreatureAIBehavior = null
var _evaluation_remaining: float = 0.0

func _ready() -> void:
    if body == null:
        _resolve_dependencies()

func configure(value_body: CharacterBody2D, value_habitat: HabitatArea2D, seed_value: int, value_profile_id: StringName = &"") -> void:
    body = value_body
    habitat = value_habitat
    rng.seed = seed_value
    if value_profile_id != &"":
        profile_id = value_profile_id
    _resolve_dependencies()
    _evaluation_remaining = 0.0

func set_enabled(value: bool) -> void:
    enabled = value
    if not enabled and body != null:
        body.velocity = Vector2.ZERO

func physics_step(delta: float) -> void:
    if not enabled or body == null:
        if body != null:
            body.velocity = Vector2.ZERO
        return
    if profile == null:
        _resolve_profile()
    if perception != null:
        perception.process_step(delta)
    _refresh_context()
    _evaluation_remaining -= delta
    if _active_behavior == null or _evaluation_remaining <= 0.0:
        _select_behavior()
        _evaluation_remaining = profile.evaluation_interval if profile != null else 0.25
    var desired_velocity: Vector2 = Vector2.ZERO
    if _active_behavior != null:
        desired_velocity = _active_behavior.get_desired_velocity(context, delta)
    body.velocity = desired_velocity
    body.move_and_slide()

func get_active_behavior_id() -> StringName:
    if _active_behavior == null:
        return &""
    return _active_behavior.behavior_id

func force_reevaluation() -> void:
    _evaluation_remaining = 0.0

func _resolve_dependencies() -> void:
    if body == null:
        body = get_parent() as CharacterBody2D
    perception = get_node_or_null(perception_path) as CreaturePerceptionComponent
    if perception != null:
        perception.configure(body)
    _resolve_profile()
    _collect_behaviors()
    _refresh_context()

func _resolve_profile() -> void:
    profile = ContentDB.get_definition(profile_id) as CreatureAIProfileDefinition
    if profile == null:
        push_warning("CreatureAIController could not resolve AI profile %s" % String(profile_id))
        return
    if perception != null:
        perception.maximum_radius = maxf(profile.notice_radius, profile.flee_until_distance)

func _collect_behaviors() -> void:
    _behaviors.clear()
    var container: Node = get_node_or_null(behavior_container_path)
    if container == null:
        return
    for child: Node in container.get_children():
        var behavior: CreatureAIBehavior = child as CreatureAIBehavior
        if behavior != null:
            _behaviors.append(behavior)

func _refresh_context() -> void:
    context.body = body
    context.habitat = habitat
    context.perception = perception
    context.profile = profile
    context.rng = rng
    if habitat != null:
        context.home_position = habitat.global_position
    elif body != null and context.home_position == Vector2.ZERO:
        context.home_position = body.global_position

func _select_behavior() -> void:
    var best_behavior: CreatureAIBehavior = null
    var best_score: float = -INF
    for behavior: CreatureAIBehavior in _behaviors:
        if not behavior.enabled:
            continue
        var score: float = behavior.evaluate_score(context)
        if score == -INF:
            continue
        if profile != null and profile.score_jitter > 0.0:
            score += rng.randf_range(0.0, profile.score_jitter)
        if best_behavior == null or score > best_score or (is_equal_approx(score, best_score) and String(behavior.behavior_id).casecmp_to(String(best_behavior.behavior_id)) < 0):
            best_behavior = behavior
            best_score = score
    if best_behavior == _active_behavior:
        return
    var previous_id: StringName = get_active_behavior_id()
    if _active_behavior != null:
        _active_behavior.exit_behavior(context)
    _active_behavior = best_behavior
    if _active_behavior != null:
        _active_behavior.enter_behavior(context)
    active_behavior_changed.emit(previous_id, get_active_behavior_id())
