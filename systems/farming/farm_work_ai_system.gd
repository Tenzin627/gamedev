extends RegionLocalSystem
class_name FarmWorkAISystem

signal work_completed(instance_id: String, work_tag: StringName, cell: Vector2i)

# Helpers are intentionally slower/less productive than direct player work.
# The demo uses frequent visible work pulses, then scales harvested/gathered
# output to 40% so automation feels helpful without replacing the player.
@export_range(0.001, 1.0, 0.001) var base_output_per_pulse: float = 0.08
@export_range(0.05, 1.0, 0.05) var helper_yield_multiplier: float = 0.4
@export var work_pulse_seconds: float = 1.0

const ACTION_PROGRESS_REQUIRED: float = 1.0

var _elapsed: float = 0.0
var _progress_by_creature: Dictionary = {}
var _current_work_by_creature: Dictionary = {}

func _process(delta: float) -> void:
    if region_root == null:
        return
    _elapsed += delta
    if _elapsed < work_pulse_seconds:
        return
    _elapsed = 0.0
    _run_work_pulse()

func _run_work_pulse() -> void:
    var assignment: FarmAssignmentSystem = region_root.get_local_system(&"FarmAssignmentSystem") as FarmAssignmentSystem
    var farm: FarmPlotSystem = region_root.get_local_system(&"FarmPlotSystem") as FarmPlotSystem
    var farm_storage: FarmStorageSystem = region_root.get_local_system(&"FarmStorageSystem") as FarmStorageSystem
    var tile_content: TileWorldContentSystem = region_root.get_local_system(&"TileWorldContentSystem") as TileWorldContentSystem
    if assignment == null or farm == null:
        return

    var model: CreatureCollectionModel = CreatureCollectionModel.new()
    var reserved_cells: Dictionary = {}
    var reserved_resources: Dictionary = {}
    for instance_id: String in assignment.get_assigned_ids():
        var creature: CreatureInstanceData = model.get_creature(instance_id)
        if creature == null:
            _clear_creature_work(instance_id)
            continue
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
        if species == null:
            _clear_creature_work(instance_id)
            continue

        var profile: FarmWorkProfileDefinition = _resolve_work_profile(species)
        var work: Dictionary = _choose_work(profile, farm, farm_storage, tile_content, reserved_cells, reserved_resources)
        if work.is_empty():
            _clear_creature_work(instance_id)
            continue

        var cell: Vector2i = work.get("cell", Vector2i.ZERO) as Vector2i
        var resource_key: String = str(work.get("resource_key", ""))
        if not resource_key.is_empty():
            reserved_resources[resource_key] = true
        else:
            reserved_cells[_cell_key(cell)] = true
        _current_work_by_creature[instance_id] = work.duplicate(true)

        var rate_multiplier: float = 1.0 if profile == null else profile.work_rate_multiplier
        var progress: float = float(_progress_by_creature.get(instance_id, 0.0)) + (base_output_per_pulse * rate_multiplier)
        if progress + 0.000001 < ACTION_PROGRESS_REQUIRED:
            _progress_by_creature[instance_id] = progress
            continue

        _progress_by_creature[instance_id] = progress - ACTION_PROGRESS_REQUIRED
        var work_tag: StringName = StringName(str(work.get("tag", "")))
        if _perform_work(work_tag, cell, work, farm, farm_storage, tile_content):
            var completed_tag: StringName = &"resource_output" if work_tag == &"resource" and bool(work.get("produced_items", false)) else work_tag
            work_completed.emit(instance_id, completed_tag, cell)

func _clear_creature_work(instance_id: String) -> void:
    _current_work_by_creature.erase(instance_id)
    _progress_by_creature.erase(instance_id)

func _resolve_work_profile(species: CreatureSpeciesDefinition) -> FarmWorkProfileDefinition:
    if species == null or species.farm_work_profile_id == &"":
        return null
    return ContentDB.get_definition(species.farm_work_profile_id) as FarmWorkProfileDefinition

func _choose_work(profile: FarmWorkProfileDefinition, farm: FarmPlotSystem, farm_storage: FarmStorageSystem, tile_content: TileWorldContentSystem, reserved_cells: Dictionary, reserved_resources: Dictionary) -> Dictionary:
    if profile == null:
        return {}
    for rule: FarmWorkRule in profile.get_enabled_rules():
        var work: Dictionary = _find_work_for_rule(rule.kind, profile.auto_till_cell_limit, farm, farm_storage, tile_content, reserved_cells, reserved_resources)
        if not work.is_empty():
            return work
    return {}

func _find_work_for_rule(kind: int, till_limit: int, farm: FarmPlotSystem, farm_storage: FarmStorageSystem, tile_content: TileWorldContentSystem, reserved_cells: Dictionary, reserved_resources: Dictionary) -> Dictionary:
    var cells: Array[Vector2i] = farm.get_owned_cells()
    match kind:
        FarmWorkRule.Kind.HARVEST:
            for cell: Vector2i in cells:
                if not _is_reserved(cell, reserved_cells) and bool(farm.get_plot(cell).get("ready", false)):
                    return {"tag": &"gather", "cell": cell}
        FarmWorkRule.Kind.WATER:
            for cell: Vector2i in cells:
                if _is_reserved(cell, reserved_cells):
                    continue
                var plot: Dictionary = farm.get_plot(cell)
                if bool(plot.get("tilled", false)) and not bool(plot.get("watered", false)) and String(plot.get("crop_id", "")) != "":
                    return {"tag": &"water", "cell": cell}
        FarmWorkRule.Kind.PLANT:
            if farm_storage != null and farm_storage.storage != null:
                var crop: CropDefinition = _find_available_crop(farm_storage.storage)
                if crop != null:
                    for cell: Vector2i in cells:
                        if _is_reserved(cell, reserved_cells):
                            continue
                        var plot: Dictionary = farm.get_plot(cell)
                        if bool(plot.get("tilled", false)) and String(plot.get("crop_id", "")).is_empty():
                            return {"tag": &"plant", "cell": cell, "crop_id": crop.content_id, "seed_item_id": crop.seed_item_id}
        FarmWorkRule.Kind.TILL:
            var tilled_count: int = 0
            for cell: Vector2i in cells:
                if bool(farm.get_plot(cell).get("tilled", false)):
                    tilled_count += 1
            if tilled_count < mini(till_limit, cells.size()):
                for cell: Vector2i in cells:
                    if not _is_reserved(cell, reserved_cells) and not bool(farm.get_plot(cell).get("tilled", false)):
                        return {"tag": &"till", "cell": cell}
        FarmWorkRule.Kind.GATHER_RESOURCE:
            if tile_content != null:
                for job: Dictionary in tile_content.get_helper_gather_jobs():
                    var resource_key: String = str(job.get("resource_key", ""))
                    if not resource_key.is_empty() and not reserved_resources.has(resource_key):
                        return {
                            "tag": &"resource",
                            "cell": job.get("cell", Vector2i.ZERO),
                            "target_position": job.get("target_position", Vector2.ZERO),
                            "resource_key": resource_key,
                            "definition_id": job.get("definition_id", &""),
                        }
    return {}

func _perform_work(work_tag: StringName, cell: Vector2i, work: Dictionary, farm: FarmPlotSystem, farm_storage: FarmStorageSystem, tile_content: TileWorldContentSystem) -> bool:
    if work_tag == &"till":
        return farm.till(cell)
    if work_tag == &"water":
        return farm.water(cell)
    if work_tag == &"plant":
        if farm_storage == null or farm_storage.storage == null:
            return false
        var crop_id: StringName = StringName(str(work.get("crop_id", "")))
        var seed_item_id: StringName = StringName(str(work.get("seed_item_id", "")))
        var crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
        if crop == null or seed_item_id == &"" or farm_storage.storage.get_total_quantity(seed_item_id) <= 0:
            return false
        var remaining: int = farm_storage.storage.remove_item(seed_item_id, 1)
        if remaining > 0:
            return false
        if not farm.plant(cell, crop):
            farm_storage.storage.add_item(seed_item_id, 1)
            return false
        return true
    if work_tag == &"gather":
        if farm_storage == null or farm_storage.storage == null:
            return false
        var amount: int = farm.harvest_to_container(cell, farm_storage.storage, helper_yield_multiplier)
        if amount <= 0:
            return false
        farm_storage.record_auto_harvest(amount)
        return true
    if work_tag == &"resource":
        if tile_content == null or farm_storage == null or farm_storage.storage == null:
            return false
        var resource_key: String = str(work.get("resource_key", ""))
        var result: Dictionary = tile_content.helper_gather_resource(resource_key, farm_storage.storage, helper_yield_multiplier)
        if not bool(result.get("performed", false)):
            return false
        var item_count: int = int(result.get("items", 0))
        if item_count > 0:
            farm_storage.record_auto_material_run(item_count)
            work["produced_items"] = true
        return true
    return false

func _find_available_crop(storage: ItemSlotContainerComponent) -> CropDefinition:
    if storage == null:
        return null
    for content_id: StringName in ContentDB.get_all_ids():
        var crop: CropDefinition = ContentDB.get_definition(content_id) as CropDefinition
        if crop != null and crop.seed_item_id != &"" and storage.get_total_quantity(crop.seed_item_id) > 0:
            return crop
    return null

func _is_reserved(cell: Vector2i, reserved_cells: Dictionary) -> bool:
    return reserved_cells.has(_cell_key(cell))

func _cell_key(cell: Vector2i) -> String:
    return "%d,%d" % [cell.x, cell.y]

func get_current_work(instance_id: String) -> Dictionary:
    var value: Variant = _current_work_by_creature.get(instance_id, {})
    return Dictionary(value).duplicate(true) if value is Dictionary else {}

func get_progress(instance_id: String) -> float:
    return clampf(float(_progress_by_creature.get(instance_id, 0.0)), 0.0, 1.0)

func export_runtime_state() -> Dictionary:
    return {"progress": _progress_by_creature.duplicate(true)}

func import_runtime_state(state: Dictionary) -> void:
    var value: Variant = state.get("progress", {})
    _progress_by_creature = Dictionary(value).duplicate(true) if value is Dictionary else {}
