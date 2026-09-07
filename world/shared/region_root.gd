extends Node2D
class_name RegionRoot

signal region_initialized(region_id: StringName, zone_id: StringName)
signal runtime_state_restored(zone_id: StringName)
signal runtime_state_persisted(zone_id: StringName)

const EXPECTED_TILE_LAYERS: Array[StringName] = [
    &"Ground",
    &"GroundDetail",
    &"Paths",
    &"Water",
    &"TerrainStructure",
    &"UnderProps",
    &"StaticProps",
    &"Forage",
    &"ResourceTiles",
    &"Overhang",
    &"Canopy",
]

const EXPECTED_CONTAINERS: Array[StringName] = [
    &"TileLayers",
    &"Environment",
    &"WorldObjects",
    &"NPCs",
    &"Habitats",
    &"Creatures",
    &"Resources",
    &"Buildings",
    &"Waymarks",
    &"Entrances",
    &"SpawnPoints",
    &"Navigation",
    &"AudioZones",
    &"Systems",
]

@export var region_definition: RegionDefinition = null
@export var zone_definition: ZoneDefinition = null
@export var validate_on_ready: bool = true
@export var persist_runtime_state: bool = true

var _runtime_restored: bool = false

func _ready() -> void:
    add_to_group(&"region_root")
    _bind_local_systems()
    if persist_runtime_state:
        restore_runtime_state()
    if validate_on_ready:
        var errors: PackedStringArray = validate_region_structure()
        for error_message: String in errors:
            push_error("RegionRoot [%s / %s]: %s" % [String(get_region_id()), String(get_zone_id()), error_message])
    SceneRouter.notify_region_ready(self)
    region_initialized.emit(get_region_id(), get_zone_id())

func _exit_tree() -> void:
    if persist_runtime_state and _runtime_restored and get_zone_id() != &"":
        persist_current_runtime_state()

func get_region_id() -> StringName:
    if zone_definition != null and zone_definition.region_id != &"":
        return zone_definition.region_id
    if region_definition == null:
        return &""
    return region_definition.content_id

func get_zone_id() -> StringName:
    if zone_definition == null:
        return &""
    return zone_definition.content_id

func get_default_spawn_id() -> StringName:
    if zone_definition != null and zone_definition.default_spawn_id != &"":
        return zone_definition.default_spawn_id
    if region_definition == null or region_definition.default_spawn_id == &"":
        return &"default"
    return region_definition.default_spawn_id

func get_region_container(container_name: StringName) -> Node:
    return get_node_or_null(NodePath(String(container_name)))

func get_tile_layer(layer_name: StringName) -> TileMapLayer:
    var node: Node = get_node_or_null(NodePath("TileLayers/%s" % String(layer_name)))
    return node as TileMapLayer

func get_spawn_point(spawn_id: StringName) -> SpawnPoint2D:
    var spawn_container: Node = get_node_or_null(^"SpawnPoints")
    if spawn_container == null:
        return null
    for child: Node in spawn_container.get_children():
        if child is SpawnPoint2D:
            var spawn_point: SpawnPoint2D = child as SpawnPoint2D
            if spawn_point.spawn_id == spawn_id:
                return spawn_point
    if spawn_id != get_default_spawn_id():
        return get_spawn_point(get_default_spawn_id())
    return null

func get_local_system(system_name: StringName) -> RegionLocalSystem:
    var node: Node = get_node_or_null(NodePath("Systems/%s" % String(system_name)))
    return node as RegionLocalSystem

func persist_current_runtime_state() -> void:
    if not persist_runtime_state: return
    var zone_id: StringName = get_zone_id()
    if zone_id == &"":
        return
    GameSession.set_region_runtime_state(zone_id, export_runtime_state())
    runtime_state_persisted.emit(zone_id)

func export_runtime_state() -> Dictionary:
    var system_states: Dictionary = {}
    var systems: Node = get_node_or_null(^"Systems")
    if systems != null:
        for child: Node in systems.get_children():
            if child is RegionLocalSystem:
                var local_system: RegionLocalSystem = child as RegionLocalSystem
                system_states[String(child.name)] = local_system.export_runtime_state()
    return {
        "region_id": String(get_region_id()),
        "zone_id": String(get_zone_id()),
        "systems": system_states,
    }

func restore_runtime_state() -> void:
    _runtime_restored = true
    var zone_id: StringName = get_zone_id()
    if zone_id == &"":
        return
    var state: Dictionary = GameSession.get_region_runtime_state(zone_id)
    if state.is_empty():
        return
    import_runtime_state(state)
    runtime_state_restored.emit(zone_id)

func import_runtime_state(state: Dictionary) -> void:
    var systems_state_variant: Variant = state.get("systems", {})
    if not systems_state_variant is Dictionary:
        return
    var systems_state: Dictionary = Dictionary(systems_state_variant)
    var systems: Node = get_node_or_null(^"Systems")
    if systems == null:
        return
    for child: Node in systems.get_children():
        if not child is RegionLocalSystem:
            continue
        var key: String = String(child.name)
        var child_state_variant: Variant = systems_state.get(key, {})
        if child_state_variant is Dictionary:
            (child as RegionLocalSystem).import_runtime_state(Dictionary(child_state_variant))

func validate_region_structure() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if region_definition == null:
        errors.append("Missing RegionDefinition")
    else:
        errors.append_array(region_definition.validate_definition())

    if zone_definition != null:
        errors.append_array(zone_definition.validate_definition())
        if region_definition != null and zone_definition.region_id != region_definition.content_id:
            errors.append("Zone %s belongs to %s but RegionRoot uses %s" % [String(zone_definition.content_id), String(zone_definition.region_id), String(region_definition.content_id)])

    for container_name: StringName in EXPECTED_CONTAINERS:
        if get_region_container(container_name) == null:
            errors.append("Missing required container: %s" % String(container_name))

    for layer_name: StringName in EXPECTED_TILE_LAYERS:
        var layer: TileMapLayer = get_tile_layer(layer_name)
        if layer == null:
            errors.append("Missing TileMapLayer: %s" % String(layer_name))
            continue
        if layer.tile_set == null:
            errors.append("TileMapLayer %s has no TileSet" % String(layer_name))
        elif layer.tile_set.tile_size != Vector2i(WorldGrid.TILE_SIZE_PX, WorldGrid.TILE_SIZE_PX):
            errors.append("TileMapLayer %s TileSet must use %dx%d tiles" % [String(layer_name), WorldGrid.TILE_SIZE_PX, WorldGrid.TILE_SIZE_PX])

    var default_spawn: SpawnPoint2D = get_spawn_point(get_default_spawn_id())
    if default_spawn == null:
        errors.append("Missing default SpawnPoint2D: %s" % String(get_default_spawn_id()))

    var systems: Node = get_region_container(&"Systems")
    if systems != null:
        _validate_local_system(systems, &"RegionStateController", errors)
        _validate_local_system(systems, &"EncounterSpawner", errors)
        _validate_local_system(systems, &"AmbientController", errors)
        _validate_local_system(systems, &"WaymarkTravelCoordinator", errors)
        _validate_local_system(systems, &"PlayerCoordinator", errors)
        _validate_local_system(systems, &"WildBattleCoordinator", errors)
        _validate_local_system(systems, &"TileWorldContentSystem", errors)

    _validate_habitat_instances(errors)
    _validate_waymark_instances(errors)
    return errors

func _bind_local_systems() -> void:
    var systems: Node = get_node_or_null(^"Systems")
    if systems == null:
        return
    for child: Node in systems.get_children():
        if child is RegionLocalSystem:
            (child as RegionLocalSystem).bind_region(self)

func _validate_local_system(systems: Node, node_name: StringName, errors: PackedStringArray) -> void:
    var child: Node = systems.get_node_or_null(NodePath(String(node_name)))
    if child == null:
        errors.append("Missing local system anchor: %s" % String(node_name))
    elif not child is RegionLocalSystem:
        errors.append("Local system %s must extend RegionLocalSystem" % String(node_name))


func _validate_habitat_instances(errors: PackedStringArray) -> void:
    var habitat_container: Node = get_region_container(&"Habitats")
    if habitat_container == null:
        return
    var seen_ids: Dictionary = {}
    _validate_habitat_node_recursive(habitat_container, seen_ids, errors)

func _validate_habitat_node_recursive(node: Node, seen_ids: Dictionary, errors: PackedStringArray) -> void:
    for child: Node in node.get_children():
        if child is HabitatArea2D:
            var habitat: HabitatArea2D = child as HabitatArea2D
            errors.append_array(habitat.validate_habitat_area())
            var habitat_key: String = String(habitat.habitat_instance_id)
            if not habitat_key.is_empty():
                if seen_ids.has(habitat_key):
                    errors.append("Duplicate habitat_instance_id: %s" % habitat_key)
                seen_ids[habitat_key] = true
        _validate_habitat_node_recursive(child, seen_ids, errors)

func _validate_waymark_instances(errors: PackedStringArray) -> void:
    var waymark_container: Node = get_region_container(&"Waymarks")
    if waymark_container == null:
        return
    _validate_waymark_node_recursive(waymark_container, errors)

func _validate_waymark_node_recursive(node: Node, errors: PackedStringArray) -> void:
    for child: Node in node.get_children():
        if child is WaymarkPoint2D:
            errors.append_array((child as WaymarkPoint2D).validate_waymark_point())
        _validate_waymark_node_recursive(child, errors)
