extends ContentDefinition
class_name CreatureSpeciesDefinition

@export_enum("Attack", "Speed", "Guard") var archetype: String = "Attack"
@export_enum("Baby", "Teen", "Adult") var life_stage: String = "Baby"
@export var base_health: int = 10
@export var base_power: int = 5
@export_range(0.05, 0.95, 0.01) var base_bond_chance: float = 0.55
@export var habitat_tags: Array[StringName] = []
@export var farm_work_profile_id: StringName = &""
@export var move_pool_ids: Array[StringName] = []
@export var trait_pool_ids: Array[StringName] = []
@export var ai_profile_id: StringName = &"ai_profile.wild.balanced"
@export_category("Overworld Visual")
@export var world_texture: Texture2D
@export var world_sprite_frames: SpriteFrames
@export var world_visual_scale: Vector2 = Vector2(0.265625, 0.2675)
@export var world_visual_offset: Vector2 = Vector2(0.0, -20.5)
@export var world_visual_modulate: Color = Color.WHITE
@export_file("*.tscn") var world_actor_scene_path: String = "res://actors/creatures/wild_creature_actor.tscn"

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if archetype != "Attack" and archetype != "Speed" and archetype != "Guard":
        errors.append("Creature %s has invalid archetype" % String(content_id))
    if life_stage != "Baby" and life_stage != "Teen" and life_stage != "Adult":
        errors.append("Creature %s has invalid life_stage" % String(content_id))
    if base_health < 1:
        errors.append("Creature %s base_health must be >= 1" % String(content_id))
    if base_power < 0:
        errors.append("Creature %s base_power must be >= 0" % String(content_id))
    if base_bond_chance < 0.05 or base_bond_chance > 0.95:
        errors.append("Creature %s base_bond_chance must be between 0.05 and 0.95" % String(content_id))
    if habitat_tags.is_empty():
        errors.append("Creature %s should define at least one habitat tag" % String(content_id))
    if farm_work_profile_id != &"" and not ContentDB.get_definition(farm_work_profile_id) is FarmWorkProfileDefinition:
        errors.append("Creature %s references missing farm work profile %s" % [String(content_id), String(farm_work_profile_id)])
    if ai_profile_id == &"":
        errors.append("Creature %s is missing ai_profile_id" % String(content_id))
    elif not ContentDB.get_definition(ai_profile_id) is CreatureAIProfileDefinition:
        errors.append("Creature %s references missing/non-AI-profile content %s" % [String(content_id), String(ai_profile_id)])
    if world_actor_scene_path.is_empty():
        errors.append("Creature %s is missing world_actor_scene_path" % String(content_id))
    elif not ResourceLoader.exists(world_actor_scene_path, "PackedScene"):
        errors.append("Creature %s world actor scene does not exist: %s" % [String(content_id), world_actor_scene_path])
    if world_sprite_frames != null:
        var required_animations: Array[StringName] = [
            &"idle_n", &"idle_e", &"idle_s", &"idle_w",
            &"walk_n", &"walk_e", &"walk_s", &"walk_w",
        ]
        for animation_name: StringName in required_animations:
            if not world_sprite_frames.has_animation(animation_name):
                errors.append("Creature %s overworld SpriteFrames is missing animation %s" % [String(content_id), String(animation_name)])
    elif world_texture == null:
        errors.append("Creature %s needs world_sprite_frames or a world_texture fallback" % String(content_id))

    var seen_moves: Dictionary = {}
    for move_id: StringName in move_pool_ids:
        if move_id == &"":
            errors.append("Creature %s has an empty move ID" % String(content_id))
            continue
        if seen_moves.has(move_id):
            errors.append("Creature %s repeats move ID %s" % [String(content_id), String(move_id)])
            continue
        seen_moves[move_id] = true
        if not ContentDB.get_definition(move_id) is MoveDefinition:
            errors.append("Creature %s references missing/non-move content %s" % [String(content_id), String(move_id)])
    if move_pool_ids.is_empty():
        errors.append("Creature %s should define at least one move" % String(content_id))

    var valid_trait_count: int = 0
    var seen_traits: Dictionary = {}
    for trait_id: StringName in trait_pool_ids:
        if trait_id == &"":
            errors.append("Creature %s has an empty trait ID" % String(content_id))
            continue
        if seen_traits.has(trait_id):
            errors.append("Creature %s repeats trait ID %s" % [String(content_id), String(trait_id)])
            continue
        seen_traits[trait_id] = true
        var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
        if trait_definition == null:
            errors.append("Creature %s references missing/non-trait content %s" % [String(content_id), String(trait_id)])
            continue
        if trait_definition.archetype != archetype:
            errors.append("Creature %s trait %s is %s but creature archetype is %s" % [String(content_id), String(trait_id), trait_definition.archetype, archetype])
            continue
        valid_trait_count += 1
    if valid_trait_count < CreatureInstanceData.MAX_TRAIT_CANDIDATES:
        errors.append("Creature %s needs at least %d valid %s trait candidates" % [String(content_id), CreatureInstanceData.MAX_TRAIT_CANDIDATES, archetype])
    return errors
