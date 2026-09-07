extends Area2D
class_name InteractorComponent

signal focus_changed(current: InteractableComponent, previous: InteractableComponent)
signal prompt_changed(text: String, action: StringName)
signal interaction_succeeded(target: InteractableComponent, action: StringName)
signal interaction_failed(text: String)

@export var enabled: bool = true
@export var refresh_every_physics_frame: bool = true
@export var facing_source_path: NodePath = NodePath("../AnimationComponent")
@export_range(8.0, 160.0, 1.0) var max_interaction_distance: float = 52.0
@export_range(-1.0, 1.0, 0.05) var front_facing_threshold: float = -0.05
@export_range(0.0, 64.0, 1.0) var facing_bias_distance: float = 32.0
@export var no_target_feedback: String = "Nothing nearby to interact with."
@export var unavailable_feedback: String = "Can't interact right now."

var focused_interactable: InteractableComponent
var _owner_actor: Node
var _facing_source: ActorAnimationComponent

func _ready() -> void:
    _owner_actor = get_parent()
    _resolve_facing_source()
    area_entered.connect(_on_area_changed)
    area_exited.connect(_on_area_changed)
    set_physics_process(refresh_every_physics_frame)
    call_deferred("refresh_focus")

func _physics_process(_delta: float) -> void:
    if refresh_every_physics_frame:
        refresh_focus()

func get_best_interactable() -> InteractableComponent:
    return _get_best_candidate(true)

func refresh_focus() -> void:
    var next := get_best_interactable()
    if next == focused_interactable:
        return

    var previous := focused_interactable
    focused_interactable = next
    focus_changed.emit(focused_interactable, previous)

    if focused_interactable == null:
        prompt_changed.emit("", &"")
    else:
        prompt_changed.emit(
            focused_interactable.get_prompt_text(_owner_actor),
            focused_interactable.action_name
        )

func interact() -> bool:
    if not enabled:
        _emit_failure(unavailable_feedback)
        return false

    refresh_focus()
    if focused_interactable == null:
        # Disabled/unavailable interactables remain detectable so the player gets the
        # object's actual reason instead of a misleading "nothing nearby" message.
        var blocked_target := _get_best_candidate(false, true)
        if blocked_target != null:
            _emit_failure(blocked_target.get_unavailable_text(_owner_actor))
        else:
            _emit_failure(no_target_feedback)
        return false

    var target := focused_interactable
    var action := target.action_name
    if not target.can_interact(_owner_actor):
        _emit_failure(target.get_unavailable_text(_owner_actor))
        call_deferred("refresh_focus")
        return false

    var success := target.request_interaction(_owner_actor)
    if success:
        interaction_succeeded.emit(target, action)
    else:
        _emit_failure(target.get_unavailable_text(_owner_actor))
    call_deferred("refresh_focus")
    return success

func get_prompt_text() -> String:
    if focused_interactable == null:
        return ""
    return focused_interactable.get_prompt_text(_owner_actor)

func _get_best_candidate(require_available: bool, require_unavailable: bool = false) -> InteractableComponent:
    if not enabled:
        return null

    var best: InteractableComponent = null
    var best_front := false
    var best_priority := -2147483648
    var best_score := INF
    var best_instance_id: int = 1 << 62
    var origin := _get_interaction_origin()
    var facing := _get_facing_vector()
    var max_distance_sq := max_interaction_distance * max_interaction_distance
    var facing_bias_sq := facing_bias_distance * facing_bias_distance

    for area in get_overlapping_areas():
        if not area is InteractableComponent:
            continue
        var candidate := area as InteractableComponent
        var available := candidate.can_interact(_owner_actor)
        if require_available and not available:
            continue
        if require_unavailable and available:
            continue

        var target_position := candidate.get_interaction_position()
        var offset := target_position - origin
        var distance_sq := offset.length_squared()
        if distance_sq > max_distance_sq:
            continue

        var facing_dot := 0.0
        if not offset.is_zero_approx() and not facing.is_zero_approx():
            facing_dot = facing.dot(offset.normalized())
        var candidate_front := facing_dot >= front_facing_threshold

        # Facing is the first tie-break tier: an object in front beats one behind.
        # Within that tier, authored priority stays authoritative; distance/facing
        # then resolves close choices predictably.
        var candidate_score := distance_sq - (facing_dot * facing_bias_sq)
        var candidate_priority := candidate.get_interaction_priority(_owner_actor)
        var candidate_instance_id := candidate.get_instance_id()
        var is_better := false

        if best == null:
            is_better = true
        elif candidate_front and not best_front:
            is_better = true
        elif candidate_front == best_front and candidate_priority > best_priority:
            is_better = true
        elif candidate_front == best_front and candidate_priority == best_priority and candidate_score < best_score:
            is_better = true
        elif candidate_front == best_front and candidate_priority == best_priority and is_equal_approx(candidate_score, best_score) and candidate_instance_id < best_instance_id:
            is_better = true

        if is_better:
            best = candidate
            best_front = candidate_front
            best_priority = candidate_priority
            best_score = candidate_score
            best_instance_id = candidate_instance_id

    return best

func _resolve_facing_source() -> void:
    _facing_source = null
    if facing_source_path.is_empty():
        return
    var candidate := get_node_or_null(facing_source_path)
    if candidate is ActorAnimationComponent:
        _facing_source = candidate as ActorAnimationComponent

func _get_interaction_origin() -> Vector2:
    if _owner_actor is Node2D:
        return (_owner_actor as Node2D).global_position
    return global_position

func _get_facing_vector() -> Vector2:
    if _facing_source != null:
        return _facing_source.facing_vector.normalized()
    return Vector2.DOWN

func _emit_failure(text: String) -> void:
    var message := text.strip_edges()
    if message.is_empty():
        message = unavailable_feedback
    interaction_failed.emit(message)

func _on_area_changed(_area: Area2D) -> void:
    call_deferred("refresh_focus")
