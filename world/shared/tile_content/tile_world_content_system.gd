extends RegionLocalSystem
class_name TileWorldContentSystem

signal forage_collected(layer_name: StringName, cell: Vector2i, plant_id: StringName, amount: int)
signal gatherable_hit(layer_name: StringName, cell: Vector2i, tool_id: StringName, durability_remaining: int)
signal gatherable_depleted(layer_name: StringName, cell: Vector2i, drops: Dictionary)
signal tile_content_respawned(layer_name: StringName, cell: Vector2i)

const FORAGE_LAYER: StringName = &"Forage"
const RESOURCE_LAYER: StringName = &"ResourceTiles"

const DATA_KIND: StringName = &"content_kind"
const DATA_ID: StringName = &"content_id"
const DATA_TILE_KEY: StringName = &"tile_key"
const DATA_DEPLETED_TILE_KEY: StringName = &"depleted_tile_key"
const DATA_PROMPT: StringName = &"prompt_text"
const DATA_RADIUS: StringName = &"interaction_radius"
const DATA_PRIORITY: StringName = &"interaction_priority"

const KIND_FORAGE := "forage"
const KIND_GATHERABLE := "gatherable"

var _runtime_root: Node2D = null
var _cell_states: Dictionary = {}
var _content_by_key: Dictionary = {}
var _layers_by_key: Dictionary = {}
var _targets_by_key: Dictionary = {}
var _respawn_timers: Dictionary = {}
var _tile_locations_by_key: Dictionary = {}

func _on_region_bound() -> void:
    _ensure_runtime_root()
    _index_tile_keys()
    _build_from_layer(FORAGE_LAYER)
    _build_from_layer(RESOURCE_LAYER)

func export_runtime_state() -> Dictionary:
    return {"cells": _cell_states.duplicate(true)}

func import_runtime_state(state: Dictionary) -> void:
    var cells_variant: Variant = state.get("cells", {})
    _cell_states = Dictionary(cells_variant).duplicate(true) if cells_variant is Dictionary else {}
    for key_variant: Variant in _content_by_key.keys():
        _apply_state_to_key(str(key_variant))

func get_state_key(layer_name: StringName, cell: Vector2i) -> String:
    return "%s|%d|%d" % [String(layer_name), cell.x, cell.y]

func _build_from_layer(layer_name: StringName) -> void:
    if region_root == null:
        return
    var layer: TileMapLayer = region_root.get_tile_layer(layer_name)
    if layer == null or layer.tile_set == null:
        return
    for cell: Vector2i in layer.get_used_cells():
        var tile_data: TileData = layer.get_cell_tile_data(cell)
        if tile_data == null:
            continue
        var content: Dictionary = _read_content(tile_data, layer, cell)
        var kind: String = str(content.get("kind", "")).to_lower()
        if kind != KIND_FORAGE and kind != KIND_GATHERABLE:
            continue
        var definition_id: StringName = StringName(str(content.get("definition_id", "")))
        if definition_id == &"":
            push_error("TileWorldContentSystem: %s %s has no content_id custom data." % [String(layer_name), str(cell)])
            continue
        if kind == KIND_FORAGE and not ContentDB.get_definition(definition_id) is PlantDefinition:
            push_error("TileWorldContentSystem: %s %s content_id must reference PlantDefinition: %s" % [String(layer_name), str(cell), String(definition_id)])
            continue
        if kind == KIND_GATHERABLE and not ContentDB.get_definition(definition_id) is GatherableResourceDefinition:
            push_error("TileWorldContentSystem: %s %s content_id must reference GatherableResourceDefinition: %s" % [String(layer_name), str(cell), String(definition_id)])
            continue
        var key: String = get_state_key(layer_name, cell)
        _content_by_key[key] = content
        _layers_by_key[key] = layer
        if kind == KIND_FORAGE:
            _create_forage_proxy(key, layer, cell, content)
        else:
            _create_gatherable_proxy(key, layer, cell, content)
        _apply_state_to_key(key)

func _read_content(tile_data: TileData, layer: TileMapLayer, cell: Vector2i) -> Dictionary:
    return {
        "kind": str(tile_data.get_custom_data(DATA_KIND)).strip_edges(),
        "definition_id": StringName(str(tile_data.get_custom_data(DATA_ID)).strip_edges()),
        "tile_key": str(tile_data.get_custom_data(DATA_TILE_KEY)).strip_edges(),
        "depleted_tile_key": str(tile_data.get_custom_data(DATA_DEPLETED_TILE_KEY)).strip_edges(),
        "prompt_text": str(tile_data.get_custom_data(DATA_PROMPT)).strip_edges(),
        "interaction_radius": maxf(float(tile_data.get_custom_data(DATA_RADIUS)), 8.0),
        "interaction_priority": int(tile_data.get_custom_data(DATA_PRIORITY)),
        "source_id": layer.get_cell_source_id(cell),
        "atlas_coords": layer.get_cell_atlas_coords(cell),
        "alternative_tile": layer.get_cell_alternative_tile(cell),
    }

func _create_forage_proxy(key: String, layer: TileMapLayer, cell: Vector2i, content: Dictionary) -> void:
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var plant: PlantDefinition = ContentDB.get_definition(definition_id) as PlantDefinition
    var interactable: InteractableComponent = InteractableComponent.new()
    interactable.name = "Forage_%s_%d_%d" % [String(layer.name), cell.x, cell.y]
    interactable.position = _cell_position_in_region(layer, cell)
    interactable.collision_layer = 16
    interactable.collision_mask = 0
    interactable.action_name = &"harvest"
    var prompt: String = str(content.get("prompt_text", ""))
    interactable.prompt_text = prompt if not prompt.is_empty() else "Collect %s" % plant.display_name
    interactable.interaction_priority = int(content.get("interaction_priority", 5))
    var shape: CollisionShape2D = CollisionShape2D.new()
    var circle: CircleShape2D = CircleShape2D.new()
    circle.radius = float(content.get("interaction_radius", 30.0))
    shape.shape = circle
    interactable.add_child(shape)
    _runtime_root.add_child(interactable)
    interactable.interaction_requested.connect(_on_forage_interaction.bind(key))
    _targets_by_key[key] = interactable

func _create_gatherable_proxy(key: String, layer: TileMapLayer, cell: Vector2i, content: Dictionary) -> void:
    var target: ToolTargetComponent = ToolTargetComponent.new()
    target.name = "Gatherable_%s_%d_%d" % [String(layer.name), cell.x, cell.y]
    target.position = _cell_position_in_region(layer, cell)
    target.collision_layer = 32
    target.collision_mask = 0
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    if definition == null:
        return
    target.accepted_tool_tags = definition.accepted_tool_tags
    target.minimum_tool_tier = definition.minimum_tool_tier
    target.tool_target_priority = int(content.get("interaction_priority", 3))
    var target_shape: CollisionShape2D = CollisionShape2D.new()
    var target_circle: CircleShape2D = CircleShape2D.new()
    target_circle.radius = float(content.get("interaction_radius", 38.0))
    target_shape.shape = target_circle
    target.add_child(target_shape)
    _runtime_root.add_child(target)
    target.tool_applied.connect(_on_gatherable_tool_applied.bind(key))
    _targets_by_key[key] = target

func _on_forage_interaction(_action: StringName, interactor_node: Node, key: String) -> void:
    var content: Dictionary = _content_by_key.get(key, {})
    if content.is_empty():
        return
    var state: Dictionary = _get_cell_state(key)
    if bool(state.get("collected", false)):
        return
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var plant: PlantDefinition = ContentDB.get_definition(definition_id) as PlantDefinition
    if plant == null:
        return
    var player: PlayerActor = interactor_node as PlayerActor
    if player == null:
        player = interactor_node.get_parent() as PlayerActor
    if player == null or player.inventory_component == null:
        return
    var amount: int = randi_range(plant.harvest_min, plant.harvest_max)
    var batch: Dictionary = {plant.harvest_item_id: amount}
    if not player.inventory_component.can_add_batch(batch):
        _show_status("Pack is full.")
        return
    player.inventory_component.add_batch(batch)
    state["collected"] = true
    _cell_states[key] = state
    _apply_state_to_key(key)
    if plant.discovery_id != &"":
        var service: ExplorationProgressService = ExplorationProgressService.new()
        add_child(service)
        service.discover(plant.discovery_id)
        service.queue_free()
    var parsed: Dictionary = _parse_key(key)
    forage_collected.emit(StringName(str(parsed.get("layer", ""))), parsed.get("cell", Vector2i.ZERO), plant.content_id, amount)
    _show_status("Gathered %s ×%d" % [plant.display_name, amount])

func _on_gatherable_tool_applied(tool: ToolDefinition, inventory: InventoryComponent, _source: Node, key: String) -> void:
    var content: Dictionary = _content_by_key.get(key, {})
    if content.is_empty() or inventory == null:
        return
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    if definition == null:
        return
    var state: Dictionary = _get_cell_state(key)
    if bool(state.get("depleted", false)):
        return
    var remaining: int = int(state.get("durability", definition.durability))
    var damage: int = maxi(tool.power, 1)
    var next_remaining: int = maxi(remaining - damage, 0)
    if next_remaining <= 0:
        var table: LootTableDefinition = ContentDB.get_definition(definition.loot_table_id) as LootTableDefinition
        var drops: Dictionary = table.roll() if table != null else {}
        if drops.is_empty():
            _show_status("Nothing useful came loose.")
            return
        if not inventory.can_add_batch(drops):
            _show_status("Pack is full.")
            return
        inventory.add_batch(drops)
        state["durability"] = 0
        state["depleted"] = true
        if definition.respawn_seconds > 0.0:
            state["respawn_at"] = Time.get_unix_time_from_system() + definition.respawn_seconds
        _cell_states[key] = state
        _apply_state_to_key(key)
        _schedule_respawn_if_needed(key)
        var parsed: Dictionary = _parse_key(key)
        gatherable_depleted.emit(StringName(str(parsed.get("layer", ""))), parsed.get("cell", Vector2i.ZERO), drops.duplicate(true))
        _show_status(_format_drops(drops))
        return
    state["durability"] = next_remaining
    _cell_states[key] = state
    var parsed: Dictionary = _parse_key(key)
    gatherable_hit.emit(StringName(str(parsed.get("layer", ""))), parsed.get("cell", Vector2i.ZERO), tool.content_id, next_remaining)

func get_helper_gather_jobs() -> Array[Dictionary]:
    var jobs: Array[Dictionary] = []
    for key_variant: Variant in _content_by_key.keys():
        var key: String = str(key_variant)
        var content: Dictionary = _content_by_key.get(key, {})
        if str(content.get("kind", "")) != KIND_GATHERABLE:
            continue
        var state: Dictionary = _get_cell_state(key)
        if bool(state.get("depleted", false)):
            continue
        var layer: TileMapLayer = _layers_by_key.get(key) as TileMapLayer
        if layer == null:
            continue
        var parsed: Dictionary = _parse_key(key)
        var cell: Vector2i = parsed.get("cell", Vector2i.ZERO) as Vector2i
        jobs.append({
            "resource_key": key,
            "cell": cell,
            "target_position": _cell_position_in_region(layer, cell),
            "definition_id": content.get("definition_id", &""),
        })
    jobs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ac: Vector2i = a.get("cell", Vector2i.ZERO) as Vector2i
        var bc: Vector2i = b.get("cell", Vector2i.ZERO) as Vector2i
        return ac.y < bc.y or (ac.y == bc.y and ac.x < bc.x)
    )
    return jobs

func helper_gather_resource(resource_key: String, target: ItemSlotContainerComponent, yield_multiplier: float = 0.4) -> Dictionary:
    var result: Dictionary = {"performed": false, "items": 0}
    if resource_key.is_empty() or target == null:
        return result
    var content: Dictionary = _content_by_key.get(resource_key, {})
    if content.is_empty() or str(content.get("kind", "")) != KIND_GATHERABLE:
        return result
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    if definition == null:
        return result
    var state: Dictionary = _get_cell_state(resource_key)
    if bool(state.get("depleted", false)):
        return result

    var remaining: int = int(state.get("durability", definition.durability))
    var next_remaining: int = maxi(remaining - 1, 0)
    if next_remaining > 0:
        state["durability"] = next_remaining
        _cell_states[resource_key] = state
        var hit_parsed: Dictionary = _parse_key(resource_key)
        gatherable_hit.emit(StringName(str(hit_parsed.get("layer", ""))), hit_parsed.get("cell", Vector2i.ZERO), &"helper.farm_creature", next_remaining)
        result["performed"] = true
        return result

    var table: LootTableDefinition = ContentDB.get_definition(definition.loot_table_id) as LootTableDefinition
    var drops: Dictionary = table.roll() if table != null else {}
    drops = _scale_helper_drops(drops, yield_multiplier)
    if drops.is_empty() or not target.can_add_batch(drops):
        return result
    var leftovers: Dictionary = target.add_batch(drops)
    if not leftovers.is_empty():
        return result

    state["durability"] = 0
    state["depleted"] = true
    if definition.respawn_seconds > 0.0:
        state["respawn_at"] = Time.get_unix_time_from_system() + definition.respawn_seconds
    _cell_states[resource_key] = state
    _apply_state_to_key(resource_key)
    _schedule_respawn_if_needed(resource_key)
    var parsed: Dictionary = _parse_key(resource_key)
    gatherable_depleted.emit(StringName(str(parsed.get("layer", ""))), parsed.get("cell", Vector2i.ZERO), drops.duplicate(true))
    var total_items: int = 0
    for amount_variant: Variant in drops.values():
        total_items += maxi(int(amount_variant), 0)
    result["performed"] = true
    result["items"] = total_items
    result["drops"] = drops.duplicate(true)
    return result

func _scale_helper_drops(drops: Dictionary, yield_multiplier: float) -> Dictionary:
    var scaled: Dictionary = {}
    var multiplier: float = clampf(yield_multiplier, 0.01, 1.0)
    for item_variant: Variant in drops.keys():
        var amount: int = maxi(int(drops[item_variant]), 0)
        if amount <= 0:
            continue
        scaled[item_variant] = maxi(1, int(ceil(float(amount) * multiplier)))
    return scaled

func _get_cell_state(key: String) -> Dictionary:
    var state_variant: Variant = _cell_states.get(key, {})
    return Dictionary(state_variant).duplicate(true) if state_variant is Dictionary else {}

func _apply_state_to_key(key: String) -> void:
    var content: Dictionary = _content_by_key.get(key, {})
    var layer: TileMapLayer = _layers_by_key.get(key) as TileMapLayer
    if content.is_empty() or layer == null:
        return
    var parsed: Dictionary = _parse_key(key)
    var cell: Vector2i = parsed.get("cell", Vector2i.ZERO)
    var state: Dictionary = _get_cell_state(key)
    var kind: String = str(content.get("kind", ""))
    if kind == KIND_FORAGE:
        var collected: bool = bool(state.get("collected", false))
        if collected:
            layer.erase_cell(cell)
        else:
            _restore_live_tile(layer, cell, content)
        var interactable: InteractableComponent = _targets_by_key.get(key) as InteractableComponent
        if interactable != null:
            interactable.enabled = not collected
        return

    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    var depleted: bool = bool(state.get("depleted", false))
    if depleted and definition != null and definition.respawn_seconds > 0.0:
        var respawn_at: float = float(state.get("respawn_at", 0.0))
        if respawn_at > 0.0 and Time.get_unix_time_from_system() >= respawn_at:
            _reset_gatherable(key)
            return
    if depleted:
        var depleted_key: String = str(content.get("depleted_tile_key", ""))
        if depleted_key.is_empty() or not _set_cell_from_tile_key(layer, cell, depleted_key):
            layer.erase_cell(cell)
    else:
        _restore_live_tile(layer, cell, content)
    var tool_target: ToolTargetComponent = _targets_by_key.get(key) as ToolTargetComponent
    if tool_target != null:
        tool_target.enabled = not depleted
    if depleted:
        _schedule_respawn_if_needed(key)

func _restore_live_tile(layer: TileMapLayer, cell: Vector2i, content: Dictionary) -> void:
    layer.set_cell(
        cell,
        int(content.get("source_id", -1)),
        content.get("atlas_coords", Vector2i.ZERO),
        int(content.get("alternative_tile", 0))
    )

func _index_tile_keys() -> void:
    _tile_locations_by_key.clear()
    if region_root == null:
        return
    var seen_sets: Dictionary = {}
    for layer_name: StringName in [FORAGE_LAYER, RESOURCE_LAYER, &"StaticProps"]:
        var layer: TileMapLayer = region_root.get_tile_layer(layer_name)
        if layer == null or layer.tile_set == null:
            continue
        var set_id: int = layer.tile_set.get_instance_id()
        if seen_sets.has(set_id):
            continue
        seen_sets[set_id] = true
        _index_tile_set(layer.tile_set)

func _index_tile_set(tile_set: TileSet) -> void:
    for source_index: int in range(tile_set.get_source_count()):
        var source_id: int = tile_set.get_source_id(source_index)
        var atlas: TileSetAtlasSource = tile_set.get_source(source_id) as TileSetAtlasSource
        if atlas == null:
            continue
        for tile_index: int in range(atlas.get_tiles_count()):
            var atlas_coords: Vector2i = atlas.get_tile_id(tile_index)
            _index_tile_location(atlas, source_id, atlas_coords, 0)
            var alt_count: int = atlas.get_alternative_tiles_count(atlas_coords)
            for alt_index: int in range(alt_count):
                var alternative: int = atlas.get_alternative_tile_id(atlas_coords, alt_index)
                if alternative != 0:
                    _index_tile_location(atlas, source_id, atlas_coords, alternative)

func _index_tile_location(atlas: TileSetAtlasSource, source_id: int, atlas_coords: Vector2i, alternative: int) -> void:
    var data: TileData = atlas.get_tile_data(atlas_coords, alternative)
    if data == null:
        return
    var tile_key: String = str(data.get_custom_data(DATA_TILE_KEY)).strip_edges()
    if tile_key.is_empty():
        return
    if _tile_locations_by_key.has(tile_key):
        push_error("TileWorldContentSystem: duplicate tile_key '%s' in TileSet." % tile_key)
        return
    _tile_locations_by_key[tile_key] = {
        "source_id": source_id,
        "atlas_coords": atlas_coords,
        "alternative_tile": alternative,
    }

func _set_cell_from_tile_key(layer: TileMapLayer, cell: Vector2i, tile_key: String) -> bool:
    var location_variant: Variant = _tile_locations_by_key.get(tile_key, null)
    if not location_variant is Dictionary:
        push_error("TileWorldContentSystem: depleted_tile_key '%s' was not found in TileSet custom data." % tile_key)
        return false
    var location: Dictionary = location_variant
    layer.set_cell(
        cell,
        int(location.get("source_id", -1)),
        location.get("atlas_coords", Vector2i.ZERO),
        int(location.get("alternative_tile", 0))
    )
    return true

func _schedule_respawn_if_needed(key: String) -> void:
    if _respawn_timers.has(key):
        return
    var content: Dictionary = _content_by_key.get(key, {})
    if content.is_empty():
        return
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    if definition == null or definition.respawn_seconds <= 0.0:
        return
    var state: Dictionary = _get_cell_state(key)
    if not bool(state.get("depleted", false)):
        return
    var now: float = Time.get_unix_time_from_system()
    var respawn_at: float = float(state.get("respawn_at", now + definition.respawn_seconds))
    var remaining: float = maxf(respawn_at - now, 0.05)
    var timer: SceneTreeTimer = get_tree().create_timer(remaining)
    _respawn_timers[key] = timer
    timer.timeout.connect(_on_respawn_timeout.bind(key))

func _on_respawn_timeout(key: String) -> void:
    _respawn_timers.erase(key)
    _reset_gatherable(key)

func _reset_gatherable(key: String) -> void:
    var content: Dictionary = _content_by_key.get(key, {})
    if content.is_empty():
        return
    var definition_id: StringName = StringName(str(content.get("definition_id", "")))
    var definition: GatherableResourceDefinition = ContentDB.get_definition(definition_id) as GatherableResourceDefinition
    if definition == null:
        return
    _cell_states[key] = {"durability": definition.durability, "depleted": false}
    _apply_state_to_key(key)
    var parsed: Dictionary = _parse_key(key)
    tile_content_respawned.emit(StringName(str(parsed.get("layer", ""))), parsed.get("cell", Vector2i.ZERO))

func _cell_position_in_region(layer: TileMapLayer, cell: Vector2i) -> Vector2:
    return region_root.to_local(layer.to_global(layer.map_to_local(cell)))

func _parse_key(key: String) -> Dictionary:
    var parts: PackedStringArray = key.split("|", false)
    if parts.size() != 3:
        return {"layer": "", "cell": Vector2i.ZERO}
    return {"layer": parts[0], "cell": Vector2i(int(parts[1]), int(parts[2]))}

func _ensure_runtime_root() -> void:
    if _runtime_root != null:
        return
    _runtime_root = Node2D.new()
    _runtime_root.name = "TileContentRuntime"
    _runtime_root.y_sort_enabled = true
    region_root.add_child(_runtime_root)

func _format_drops(drops: Dictionary) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for key_variant: Variant in drops.keys():
        var item_id: StringName = StringName(str(key_variant))
        var item: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
        var label: String = item.display_name if item != null else String(item_id)
        parts.append("%s ×%d" % [label, int(drops[key_variant])])
    return "Gathered %s" % ", ".join(parts)

func _show_status(message: String) -> void:
    if region_root == null:
        return
    var hud: CoreHUD = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
    if hud != null:
        hud.show_status_message(message, 2.0)
