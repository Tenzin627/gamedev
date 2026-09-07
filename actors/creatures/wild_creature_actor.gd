extends CharacterBody2D
class_name WildCreatureActor

signal configured(species_id: StringName, habitat_instance_id: StringName, spawn_token: String)
signal battle_encounter_requested(actor: WildCreatureActor, interactor: Node)

@export var species_id: StringName = &""
@export var habitat_instance_id: StringName = &""
@export var spawn_token: String = ""
@export var ai_enabled: bool = true

@onready var ai_controller: CreatureAIController = $CreatureAIController
@onready var perception_component: CreaturePerceptionComponent = $CreaturePerceptionComponent
@onready var name_label: Label = $NameLabel
@onready var interactable: InteractableComponent = $EncounterInteractable
@onready var animated_visual: AnimatedSprite2D = $AnimatedVisual
@onready var static_visual: Sprite2D = $StaticVisual
@onready var animation_component: ActorAnimationComponent = $AnimationComponent

var habitat: HabitatArea2D = null
var _species_definition: CreatureSpeciesDefinition = null
var _ai_seed: int = 1

func configure(value_species_id: StringName, value_habitat: HabitatArea2D, value_spawn_token: String, seed_value: int) -> void:
    species_id = value_species_id
    habitat = value_habitat
    habitat_instance_id = value_habitat.habitat_instance_id if value_habitat != null else &""
    spawn_token = value_spawn_token
    _ai_seed = seed_value
    if is_inside_tree():
        _apply_configuration()

func _ready() -> void:
    add_to_group(&"wild_creature")
    if interactable != null and not interactable.interaction_requested.is_connected(_on_interaction_requested):
        interactable.interaction_requested.connect(_on_interaction_requested)
    _apply_configuration()

func _physics_process(delta: float) -> void:
    if ai_controller == null:
        return
    ai_controller.set_enabled(ai_enabled)
    ai_controller.physics_step(delta)
    if animation_component != null:
        animation_component.set_motion(not velocity.is_zero_approx(), velocity.normalized())

func set_encounter_interaction_enabled(value: bool) -> void:
    if interactable != null:
        interactable.enabled = value
    ai_enabled = value
    if not value:
        velocity = Vector2.ZERO

func get_runtime_state() -> Dictionary:
    return {
        "species_id": String(species_id),
        "habitat_instance_id": String(habitat_instance_id),
        "spawn_token": spawn_token,
        "position_x": global_position.x,
        "position_y": global_position.y,
        "ai_seed": _ai_seed,
        "wander_seed": _ai_seed, # legacy save compatibility
    }

func _apply_configuration() -> void:
    _species_definition = ContentDB.get_definition(species_id) as CreatureSpeciesDefinition
    if _species_definition != null:
        CollectionEncyclopediaService.mark_creature_seen(species_id)
    if name_label != null:
        name_label.text = String(species_id) if _species_definition == null else _species_definition.display_name
    _apply_world_visual()
    if interactable != null:
        var display_name: String = String(species_id) if _species_definition == null else _species_definition.display_name
        interactable.prompt_text = "Challenge %s" % display_name
    if ai_controller != null:
        var ai_profile_id: StringName = &"ai_profile.wild.balanced"
        if _species_definition != null:
            ai_profile_id = _species_definition.ai_profile_id
        ai_controller.configure(self, habitat, _ai_seed, ai_profile_id)
        ai_controller.set_enabled(ai_enabled)
    configured.emit(species_id, habitat_instance_id, spawn_token)

func _apply_world_visual() -> void:
    if animated_visual == null or static_visual == null:
        return
    if _species_definition == null:
        animated_visual.visible = false
        static_visual.visible = false
        return
    animated_visual.position = _species_definition.world_visual_offset
    static_visual.position = _species_definition.world_visual_offset
    animated_visual.scale = _species_definition.world_visual_scale
    static_visual.scale = _species_definition.world_visual_scale
    animated_visual.modulate = _species_definition.world_visual_modulate
    static_visual.modulate = _species_definition.world_visual_modulate
    if _species_definition.world_sprite_frames != null:
        animated_visual.sprite_frames = _species_definition.world_sprite_frames
        animated_visual.visible = true
        static_visual.visible = false
        if animation_component != null:
            animation_component.set_state(&"idle", Vector2.DOWN)
    else:
        animated_visual.sprite_frames = null
        animated_visual.visible = false
        static_visual.texture = _species_definition.world_texture
        static_visual.visible = static_visual.texture != null

func _on_interaction_requested(_action: StringName, interactor_node: Node) -> void:
    battle_encounter_requested.emit(self, interactor_node)

