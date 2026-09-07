extends CharacterBody2D
class_name PlayerActor

@export var input_enabled: bool = true
@export var auto_apply_scene_spawn: bool = true

@onready var movement_component: CharacterMovementComponent = $MovementComponent
@onready var animation_component: ActorAnimationComponent = $AnimationComponent
@onready var interactor_component: InteractorComponent = $Interactor
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var hotbar_component: HotbarComponent = $HotbarComponent
@onready var tool_use_component: ToolUseComponent = $ToolUseComponent
@onready var farm_interaction_component: FarmInteractionComponent = $FarmInteractionComponent

func _ready() -> void:
    add_to_group(&"player")
    if auto_apply_scene_spawn:
        call_deferred("_apply_pending_spawn")

func _physics_process(delta: float) -> void:
    var direction := _read_movement_input() if input_enabled else Vector2.ZERO
    movement_component.set_desired_direction(direction)
    movement_component.physics_step(delta)
    animation_component.set_motion(movement_component.is_moving(), direction)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.echo: return
    if not input_enabled:
        return
    if InputMap.has_action(&"use_tool") and event.is_action_pressed(&"use_tool"):
        var farm_handled: bool = farm_interaction_component.try_farm_action() if farm_interaction_component != null else false
        if not farm_handled:
            tool_use_component.use_selected_tool()
        _mark_input_handled()
        return

    var interaction_pressed: bool = event.is_action_pressed(&"ui_accept")
    if InputMap.has_action(&"interact"):
        interaction_pressed = interaction_pressed or event.is_action_pressed(&"interact")
    if interaction_pressed:
        interactor_component.interact()
        # Consume the interaction press even when no target is available so the same
        # input cannot accidentally trigger another unhandled-input listener.
        _mark_input_handled()

func set_input_enabled(value: bool) -> void:
    input_enabled = value
    if hotbar_component != null:
        hotbar_component.set_input_enabled(value)
    if not input_enabled:
        movement_component.stop()
        animation_component.set_motion(false, Vector2.ZERO)

func teleport_to_spawn(spawn_id: StringName) -> bool:
    var spawn := _find_spawn_point(spawn_id)
    if spawn == null:
        var region_root := get_tree().get_first_node_in_group(&"region_root") as RegionRoot
        if region_root != null:
            spawn = region_root.get_spawn_point(region_root.get_default_spawn_id())
    if spawn == null and spawn_id != &"default":
        spawn = _find_spawn_point(&"default")
    if spawn == null:
        push_warning("PlayerActor: No valid SpawnPoint2D for '%s'; keeping authored scene position." % String(spawn_id))
        return false
    global_position = spawn.global_position
    velocity = Vector2.ZERO
    return true

func _read_movement_input() -> Vector2:
    var direction := Vector2.ZERO
    if InputMap.has_action(&"move_left") and InputMap.has_action(&"move_right") and InputMap.has_action(&"move_up") and InputMap.has_action(&"move_down"):
        direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    if direction.is_zero_approx():
        direction = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
    return direction

func _apply_pending_spawn() -> void:
    if not is_inside_tree():
        return
    var spawn_id := SceneRouter.consume_pending_spawn_id()
    if not teleport_to_spawn(spawn_id):
        push_warning("PlayerActor: Scene loaded without a usable destination spawn. Gameplay continues from the authored player position.")

func _find_spawn_point(spawn_id: StringName) -> SpawnPoint2D:
    for node in get_tree().get_nodes_in_group(&"spawn_point"):
        if node is SpawnPoint2D and (node as SpawnPoint2D).spawn_id == spawn_id:
            return node as SpawnPoint2D
    return null


func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
