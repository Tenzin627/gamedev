extends RegionLocalSystem
class_name RegionEncounterSpawner

const INVALID_SPAWN_POSITION: Vector2 = Vector2(1000000000.0, 1000000000.0)

signal creature_spawned(actor: WildCreatureActor, habitat_instance_id: StringName)
signal creature_despawned(spawn_token: String, habitat_instance_id: StringName)
signal habitat_population_changed(habitat_instance_id: StringName, live_count: int)

@export var spawning_enabled: bool = false
@export_range(0.1, 10.0, 0.1) var population_check_interval_seconds: float = 0.75
@export_range(256.0, 4096.0, 16.0) var despawn_player_distance: float = 1200.0
@export_range(1, 64, 1) var max_spawn_attempts: int = 12
@export_flags_2d_physics var spawn_blocking_mask: int = 1

var _habitats: Dictionary = {}
var _live_spawns: Dictionary = {}
var _habitat_cooldowns: Dictionary = {}
var _spawn_serial: int = 0
var _population_elapsed: float = 0.0
var _runtime_import_in_progress: bool = false

func _on_region_bound() -> void:
    _discover_habitats()
    call_deferred("_run_initial_population_cycle")

func _process(delta: float) -> void:
    _advance_habitat_cooldowns(delta)
    if not spawning_enabled or region_root == null:
        return
    _population_elapsed += delta
    if _population_elapsed < population_check_interval_seconds:
        return
    _population_elapsed = 0.0
    run_population_cycle_now()

func set_spawning_enabled(value: bool) -> void:
    spawning_enabled = value
    if spawning_enabled:
        run_population_cycle_now()

func run_population_cycle_now() -> void:
    if region_root == null:
        return
    if _habitats.is_empty():
        _discover_habitats()
    _cleanup_invalid_spawns()
    _despawn_distant_creatures()
    if not spawning_enabled:
        return
    var habitat_ids: Array[String] = _get_sorted_habitat_ids()
    for habitat_key: String in habitat_ids:
        var habitat_variant: Variant = _habitats.get(habitat_key, null)
        if not habitat_variant is HabitatArea2D:
            continue
        var habitat: HabitatArea2D = habitat_variant as HabitatArea2D
        var definition: HabitatDefinition = habitat.get_definition()
        if definition == null:
            continue
        if not definition.is_region_zone_compatible(region_root.region_definition, region_root.zone_definition):
            continue
        var current_count: int = _get_habitat_live_count(habitat.habitat_instance_id)
        var effective_limit: int = _get_effective_population_limit(definition)
        if current_count >= effective_limit:
            continue
        var cooldown: float = float(_habitat_cooldowns.get(habitat_key, 0.0))
        if cooldown > 0.0:
            continue
        var spawned_count: int = _spawn_group_for_habitat(habitat, definition)
        if spawned_count > 0:
            _habitat_cooldowns[habitat_key] = definition.respawn_delay_seconds

func claim_wild_creature_for_capture(actor: WildCreatureActor) -> bool:
    if actor == null or not is_instance_valid(actor):
        return false
    var token: String = actor.spawn_token
    if token.is_empty() or not _live_spawns.has(token):
        return false
    var habitat_id: StringName = actor.habitat_instance_id
    _live_spawns.erase(token)
    actor.queue_free()
    creature_despawned.emit(token, habitat_id)
    if habitat_id != &"":
        habitat_population_changed.emit(habitat_id, _get_habitat_live_count(habitat_id))
    return true


func resolve_wild_battle_spawn(spawn_token: String, remove_spawn: bool) -> bool:
    if spawn_token.is_empty():
        return false
    _cleanup_invalid_spawns()
    if not _live_spawns.has(spawn_token):
        return false
    if not remove_spawn:
        var actor_variant: Variant = _live_spawns.get(spawn_token, null)
        if actor_variant is WildCreatureActor and is_instance_valid(actor_variant):
            (actor_variant as WildCreatureActor).set_encounter_interaction_enabled(true)
        return true
    _despawn_token(spawn_token)
    return true

func get_live_spawn_count() -> int:
    _cleanup_invalid_spawns()
    return _live_spawns.size()

func get_population_summary() -> Dictionary:
    _cleanup_invalid_spawns()
    var result: Dictionary = {}
    var habitat_ids: Array[String] = _get_sorted_habitat_ids()
    for habitat_key: String in habitat_ids:
        result[habitat_key] = _get_habitat_live_count(StringName(habitat_key))
    return result

func get_registered_habitat_count() -> int:
    return _habitats.size()

func export_runtime_state() -> Dictionary:
    _cleanup_invalid_spawns()
    var live_state: Array[Dictionary] = []
    var tokens: Array[String] = []
    for token_variant: Variant in _live_spawns.keys():
        tokens.append(str(token_variant))
    tokens.sort()
    for token: String in tokens:
        var actor_variant: Variant = _live_spawns.get(token, null)
        if actor_variant is WildCreatureActor and is_instance_valid(actor_variant):
            var actor: WildCreatureActor = actor_variant as WildCreatureActor
            live_state.append(actor.get_runtime_state())
    return {
        "spawning_enabled": spawning_enabled,
        "spawn_serial": _spawn_serial,
        "habitat_cooldowns": _habitat_cooldowns.duplicate(true),
        "live_spawns": live_state,
    }

func import_runtime_state(state: Dictionary) -> void:
    _runtime_import_in_progress = true
    spawning_enabled = bool(state.get("spawning_enabled", spawning_enabled))
    _spawn_serial = maxi(int(state.get("spawn_serial", 0)), 0)
    var cooldown_variant: Variant = state.get("habitat_cooldowns", {})
    if cooldown_variant is Dictionary:
        _habitat_cooldowns = Dictionary(cooldown_variant).duplicate(true)
    else:
        _habitat_cooldowns = {}
    _clear_live_population()
    var live_variant: Variant = state.get("live_spawns", [])
    if live_variant is Array:
        var live_entries: Array = Array(live_variant)
        for entry_variant: Variant in live_entries:
            if entry_variant is Dictionary:
                _restore_live_spawn(Dictionary(entry_variant))
    _runtime_import_in_progress = false

func _run_initial_population_cycle() -> void:
    if not is_inside_tree() or _runtime_import_in_progress:
        return
    if _habitats.is_empty():
        _discover_habitats()
    _cleanup_invalid_spawns()
    if not spawning_enabled:
        return
    for habitat_key: String in _get_sorted_habitat_ids():
        var habitat_variant: Variant = _habitats.get(habitat_key, null)
        if not habitat_variant is HabitatArea2D:
            continue
        var habitat: HabitatArea2D = habitat_variant as HabitatArea2D
        var definition: HabitatDefinition = habitat.get_definition()
        if definition == null:
            continue
        if not definition.is_region_zone_compatible(region_root.region_definition, region_root.zone_definition):
            continue
        var target: int = mini(definition.initial_creatures, _get_effective_population_limit(definition))
        var safety: int = 0
        while _get_habitat_live_count(habitat.habitat_instance_id) < target and safety < 16:
            safety += 1
            var before: int = _get_habitat_live_count(habitat.habitat_instance_id)
            var spawned: int = _spawn_group_for_habitat(habitat, definition)
            if spawned <= 0 or _get_habitat_live_count(habitat.habitat_instance_id) <= before:
                break
        _habitat_cooldowns[habitat_key] = definition.respawn_delay_seconds

func _discover_habitats() -> void:
    _habitats.clear()
    if region_root == null:
        return
    var habitat_container: Node = region_root.get_region_container(&"Habitats")
    if habitat_container == null:
        return
    var found: Array[HabitatArea2D] = []
    _collect_habitats_recursive(habitat_container, found)
    for habitat: HabitatArea2D in found:
        if habitat.habitat_instance_id == &"":
            push_warning("RegionEncounterSpawner ignored HabitatArea2D with empty habitat_instance_id")
            continue
        var key: String = String(habitat.habitat_instance_id)
        if _habitats.has(key):
            push_error("Duplicate habitat_instance_id in loaded zone: %s" % key)
            continue
        _habitats[key] = habitat
        if not _habitat_cooldowns.has(key):
            _habitat_cooldowns[key] = 0.0

func _collect_habitats_recursive(node: Node, out_habitats: Array[HabitatArea2D]) -> void:
    for child: Node in node.get_children():
        if child is HabitatArea2D:
            out_habitats.append(child as HabitatArea2D)
        _collect_habitats_recursive(child, out_habitats)

func _spawn_group_for_habitat(habitat: HabitatArea2D, definition: HabitatDefinition) -> int:
    var rng: RandomNumberGenerator = _make_spawn_rng(habitat.habitat_instance_id)
    var entry: HabitatSpawnEntry = _roll_spawn_entry(definition, rng)
    if entry == null:
        return 0
    var current_count: int = _get_habitat_live_count(habitat.habitat_instance_id)
    var remaining_capacity: int = maxi(_get_effective_population_limit(definition) - current_count, 0)
    if remaining_capacity <= 0:
        return 0
    var requested_group: int = rng.randi_range(entry.min_group_size, entry.max_group_size)
    var group_size: int = mini(requested_group, remaining_capacity)
    var spawned: int = 0
    for _group_index: int in range(group_size):
        var spawn_position: Vector2 = _find_safe_spawn_position(habitat, definition, rng)
        if spawn_position == INVALID_SPAWN_POSITION:
            continue
        if _spawn_species(entry.species_id, habitat, spawn_position, rng):
            spawned += 1
    if spawned > 0:
        habitat_population_changed.emit(habitat.habitat_instance_id, _get_habitat_live_count(habitat.habitat_instance_id))
    return spawned

func _roll_spawn_entry(definition: HabitatDefinition, rng: RandomNumberGenerator) -> HabitatSpawnEntry:
    var valid_entries: Array[HabitatSpawnEntry] = []
    var total_weight: float = 0.0
    for entry_resource: Resource in definition.spawn_entries:
        if not entry_resource is HabitatSpawnEntry:
            continue
        var entry: HabitatSpawnEntry = entry_resource as HabitatSpawnEntry
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(entry.species_id) as CreatureSpeciesDefinition
        if species == null:
            continue
        if not _entry_matches_ecology(entry):
            continue
        if not _species_matches_habitat(species, definition):
            continue
        valid_entries.append(entry)
        total_weight += maxf(entry.spawn_weight, 0.0)
    if valid_entries.is_empty() or total_weight <= 0.0:
        return null
    var roll: float = rng.randf_range(0.0, total_weight)
    var cumulative: float = 0.0
    for entry: HabitatSpawnEntry in valid_entries:
        cumulative += maxf(entry.spawn_weight, 0.0)
        if roll <= cumulative:
            return entry
    return valid_entries[valid_entries.size() - 1]

func _species_matches_habitat(species: CreatureSpeciesDefinition, definition: HabitatDefinition) -> bool:
    for habitat_tag: StringName in definition.habitat_tags:
        if species.habitat_tags.has(habitat_tag):
            return true
    return false

func _entry_matches_ecology(entry: HabitatSpawnEntry) -> bool:
    if not entry.active_time_tags.is_empty() and not entry.active_time_tags.has(WorldTimeService.get_time_of_day_tag()):
        return false
    var ecology_key: StringName = StringName("ecology.%s.health" % String(get_region_id()))
    var health: float = float(WorldStateService.get_value(ecology_key, 1.0))
    return health >= entry.minimum_ecology_health

func _get_effective_population_limit(definition: HabitatDefinition) -> int:
    var ecology_key: StringName = StringName("ecology.%s.health" % String(get_region_id()))
    var health: float = clampf(float(WorldStateService.get_value(ecology_key, 1.0)), 0.0, 1.0)
    var multiplier: float = lerpf(0.6, 1.0, health)
    return maxi(1, int(round(float(definition.max_creatures_alive) * multiplier)))

func _find_safe_spawn_position(habitat: HabitatArea2D, definition: HabitatDefinition, rng: RandomNumberGenerator) -> Vector2:
    var player: Node2D = _resolve_player()
    for _attempt: int in range(max_spawn_attempts):
        var candidate: Vector2 = habitat.get_random_spawn_position(rng)
        if player != null and definition.minimum_player_distance > 0.0:
            if candidate.distance_to(player.global_position) < definition.minimum_player_distance:
                continue
        if _is_too_close_to_live_creature(candidate, definition.creature_spacing):
            continue
        if _is_world_position_blocked(candidate):
            continue
        return candidate
    return INVALID_SPAWN_POSITION

func _is_too_close_to_live_creature(candidate: Vector2, clearance: float) -> bool:
    if clearance <= 0.0:
        return false
    for actor_variant: Variant in _live_spawns.values():
        if actor_variant is WildCreatureActor and is_instance_valid(actor_variant):
            var actor: WildCreatureActor = actor_variant as WildCreatureActor
            if candidate.distance_to(actor.global_position) < clearance:
                return true
    return false

func _is_world_position_blocked(candidate: Vector2) -> bool:
    if spawn_blocking_mask == 0 or region_root == null:
        return false
    var world: World2D = region_root.get_world_2d()
    if world == null:
        return false
    var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    query.position = candidate
    query.collision_mask = spawn_blocking_mask
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var direct_state: PhysicsDirectSpaceState2D = world.direct_space_state
    var hits: Array[Dictionary] = direct_state.intersect_point(query, 8)
    return not hits.is_empty()

func _spawn_species(species_id: StringName, habitat: HabitatArea2D, world_position: Vector2, rng: RandomNumberGenerator) -> bool:
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(species_id) as CreatureSpeciesDefinition
    if species == null:
        return false
    var scene_resource: Resource = ResourceLoader.load(species.world_actor_scene_path)
    if not scene_resource is PackedScene:
        push_error("Wild creature scene failed to load for %s: %s" % [String(species_id), species.world_actor_scene_path])
        return false
    var actor: WildCreatureActor = (scene_resource as PackedScene).instantiate() as WildCreatureActor
    if actor == null:
        push_error("Wild creature scene root must be WildCreatureActor: %s" % species.world_actor_scene_path)
        return false
    _spawn_serial += 1
    var token: String = "%s:%s:%d" % [String(get_zone_id()), String(habitat.habitat_instance_id), _spawn_serial]
    var ai_seed: int = rng.randi()
    actor.configure(species_id, habitat, token, ai_seed)
    var creatures_container: Node = region_root.get_region_container(&"Creatures")
    if creatures_container == null:
        actor.free()
        return false
    creatures_container.add_child(actor)
    actor.global_position = world_position
    _live_spawns[token] = actor
    creature_spawned.emit(actor, habitat.habitat_instance_id)
    return true

func _restore_live_spawn(state: Dictionary) -> void:
    var species_id: StringName = StringName(str(state.get("species_id", "")))
    var habitat_id: StringName = StringName(str(state.get("habitat_instance_id", "")))
    var token: String = str(state.get("spawn_token", ""))
    if species_id == &"" or habitat_id == &"" or token.is_empty():
        return
    var habitat: HabitatArea2D = _get_habitat(habitat_id)
    if habitat == null:
        return
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(species_id) as CreatureSpeciesDefinition
    if species == null:
        return
    var scene_resource: Resource = ResourceLoader.load(species.world_actor_scene_path)
    if not scene_resource is PackedScene:
        return
    var actor: WildCreatureActor = (scene_resource as PackedScene).instantiate() as WildCreatureActor
    if actor == null:
        return
    var ai_seed: int = int(state.get("ai_seed", state.get("wander_seed", 1)))
    actor.configure(species_id, habitat, token, ai_seed)
    var creatures_container: Node = region_root.get_region_container(&"Creatures")
    if creatures_container == null:
        actor.free()
        return
    creatures_container.add_child(actor)
    actor.global_position = Vector2(float(state.get("position_x", 0.0)), float(state.get("position_y", 0.0)))
    _live_spawns[token] = actor
    creature_spawned.emit(actor, habitat_id)

func _despawn_distant_creatures() -> void:
    var player: Node2D = _resolve_player()
    if player == null or despawn_player_distance <= 0.0:
        return
    var tokens_to_remove: Array[String] = []
    for token_variant: Variant in _live_spawns.keys():
        var token: String = str(token_variant)
        var actor_variant: Variant = _live_spawns.get(token, null)
        if not actor_variant is WildCreatureActor or not is_instance_valid(actor_variant):
            tokens_to_remove.append(token)
            continue
        var actor: WildCreatureActor = actor_variant as WildCreatureActor
        if actor.global_position.distance_to(player.global_position) > despawn_player_distance:
            tokens_to_remove.append(token)
    for token: String in tokens_to_remove:
        _despawn_token(token)

func _despawn_token(token: String) -> void:
    if not _live_spawns.has(token):
        return
    var actor_variant: Variant = _live_spawns[token]
    var habitat_id: StringName = &""
    if actor_variant is WildCreatureActor and is_instance_valid(actor_variant):
        var actor: WildCreatureActor = actor_variant as WildCreatureActor
        habitat_id = actor.habitat_instance_id
        actor.queue_free()
    _live_spawns.erase(token)
    creature_despawned.emit(token, habitat_id)
    if habitat_id != &"":
        habitat_population_changed.emit(habitat_id, _get_habitat_live_count(habitat_id))

func _clear_live_population() -> void:
    var tokens: Array[String] = []
    for token_variant: Variant in _live_spawns.keys():
        tokens.append(str(token_variant))
    for token: String in tokens:
        _despawn_token(token)
    _live_spawns.clear()

func _cleanup_invalid_spawns() -> void:
    var invalid_tokens: Array[String] = []
    for token_variant: Variant in _live_spawns.keys():
        var token: String = str(token_variant)
        var actor_variant: Variant = _live_spawns.get(token, null)
        if not actor_variant is WildCreatureActor or not is_instance_valid(actor_variant):
            invalid_tokens.append(token)
    for token: String in invalid_tokens:
        _live_spawns.erase(token)

func _get_habitat_live_count(habitat_id: StringName) -> int:
    var count: int = 0
    for actor_variant: Variant in _live_spawns.values():
        if actor_variant is WildCreatureActor and is_instance_valid(actor_variant):
            var actor: WildCreatureActor = actor_variant as WildCreatureActor
            if actor.habitat_instance_id == habitat_id:
                count += 1
    return count

func _get_habitat(habitat_id: StringName) -> HabitatArea2D:
    var value: Variant = _habitats.get(String(habitat_id), null)
    return value as HabitatArea2D

func _get_sorted_habitat_ids() -> Array[String]:
    var ids: Array[String] = []
    for key_variant: Variant in _habitats.keys():
        ids.append(str(key_variant))
    ids.sort()
    return ids

func _make_spawn_rng(habitat_id: StringName) -> RandomNumberGenerator:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    var seed_text: String = "%s|%s|%d" % [String(get_zone_id()), String(habitat_id), _spawn_serial]
    var seed_value: int = seed_text.hash()
    if seed_value < 0:
        seed_value = -seed_value
    rng.seed = seed_value
    return rng

func _resolve_player() -> Node2D:
    if get_tree() == null:
        return null
    for node: Node in get_tree().get_nodes_in_group(&"player"):
        if node is Node2D:
            return node as Node2D
    return null

func _advance_habitat_cooldowns(delta: float) -> void:
    var keys: Array = _habitat_cooldowns.keys()
    for key_variant: Variant in keys:
        var key: String = str(key_variant)
        var current: float = float(_habitat_cooldowns.get(key, 0.0))
        if current > 0.0:
            _habitat_cooldowns[key] = maxf(current - delta, 0.0)
