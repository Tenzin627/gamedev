extends RegionLocalSystem
class_name FarmPlotSystem

signal plot_changed(cell: Vector2i, state: Dictionary)
signal farm_state_changed
signal farm_plot_placed(cell: Vector2i)

@export var farm_visual_path: NodePath = NodePath("../../Environment/HomeFarmPlots")
@export_range(1, 5, 1) var maximum_farm_level: int = 5

var _plots: Dictionary = {}
var _owned_cells: Dictionary = {}
var _last_processed_day: int = 1
var _ownership_initialized: bool = false

func _ready() -> void:
    _last_processed_day = WorldTimeService.get_day()
    if not WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.connect(_on_time_changed)
    call_deferred("_ensure_starter_ownership")

func _ensure_starter_ownership() -> void:
    if _ownership_initialized:
        return
    var visual: FarmPlotVisual = _get_farm_visual()
    if visual == null:
        return
    for cell: Vector2i in visual.get_starter_cells():
        _owned_cells[_cell_key(cell)] = true
    _ownership_initialized = true
    farm_state_changed.emit()

func is_cell_in_farm(cell: Vector2i) -> bool:
    _ensure_starter_ownership()
    return bool(_owned_cells.get(_cell_key(cell), false))

func is_cell_in_build_area(cell: Vector2i) -> bool:
    var visual: FarmPlotVisual = _get_farm_visual()
    return visual != null and visual.is_build_area_cell(cell)

func can_place_farm_plot(cell: Vector2i) -> bool:
    return is_cell_in_build_area(cell) and not is_cell_in_farm(cell) and get_unplaced_plot_allowance() > 0

func place_farm_plot(cell: Vector2i) -> bool:
    if not can_place_farm_plot(cell):
        return false
    _owned_cells[_cell_key(cell)] = true
    farm_plot_placed.emit(cell)
    farm_state_changed.emit()
    return true

func get_farm_level() -> int:
    # Farmer rank 0 is farm level 1. Future farmer milestones naturally raise this.
    return clampi(PlayerProgressionService.get_rank(PlayerProgressionService.TRACK_FARMER) + 1, 1, maximum_farm_level)

func get_level_plot_unlock_count(level: int = -1) -> int:
    var resolved_level: int = get_farm_level() if level < 0 else clampi(level, 1, maximum_farm_level)
    return clampi(resolved_level, 1, 5)

func get_total_unlocked_bonus_plot_capacity() -> int:
    # Level 1 adds 1, level 2 adds 2, ... level 5 adds 5.
    var level: int = get_farm_level()
    return int(mini(level, 5) * (mini(level, 5) + 1) / 2)

func get_bonus_owned_plot_count() -> int:
    _ensure_starter_ownership()
    var starter: Dictionary = {}
    var visual: FarmPlotVisual = _get_farm_visual()
    if visual != null:
        for cell: Vector2i in visual.get_starter_cells():
            starter[_cell_key(cell)] = true
    var count: int = 0
    for key: Variant in _owned_cells.keys():
        if not starter.has(String(key)):
            count += 1
    return count

func get_unplaced_plot_allowance() -> int:
    var entitlement: int = get_total_unlocked_bonus_plot_capacity()
    return maxi(entitlement - get_bonus_owned_plot_count(), 0)

func get_remaining_build_area_slots() -> int:
    _ensure_starter_ownership()
    var visual: FarmPlotVisual = _get_farm_visual()
    if visual == null:
        return 0
    var count: int = 0
    for cell: Vector2i in visual.get_build_area_cells():
        if not is_cell_in_farm(cell):
            count += 1
    return count

func get_placeable_plot_count() -> int:
    return mini(get_unplaced_plot_allowance(), get_remaining_build_area_slots())

func world_to_farm_cell(world_position: Vector2) -> Vector2i:
    var visual: FarmPlotVisual = _get_farm_visual()
    if visual == null:
        return Vector2i.ZERO
    return WorldGrid.local_to_cell(visual.to_local(world_position))

func farm_cell_to_world_center(cell: Vector2i) -> Vector2:
    var visual: FarmPlotVisual = _get_farm_visual()
    if visual == null:
        return Vector2.ZERO
    return visual.to_global(WorldGrid.cell_to_center(cell))

func get_owned_cells() -> Array[Vector2i]:
    _ensure_starter_ownership()
    var result: Array[Vector2i] = []
    for key: Variant in _owned_cells.keys():
        var parts: PackedStringArray = String(key).split(",")
        if parts.size() != 2:
            continue
        result.append(Vector2i(int(parts[0]), int(parts[1])))
    result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
    return result

func get_plot(cell: Vector2i) -> Dictionary:
    var value: Variant = _plots.get(_cell_key(cell), {})
    if value is Dictionary:
        return Dictionary(value).duplicate(true)
    return {}

func is_tilled(cell: Vector2i) -> bool:
    return bool(get_plot(cell).get("tilled", false))

func till(cell: Vector2i) -> bool:
    if not is_cell_in_farm(cell):
        return false
    var plot: Dictionary = get_plot(cell)
    if bool(plot.get("tilled", false)):
        return false
    plot["tilled"] = true
    plot["watered"] = false
    _store_plot(cell, plot)
    return true

func water(cell: Vector2i) -> bool:
    if not is_cell_in_farm(cell):
        return false
    var plot: Dictionary = get_plot(cell)
    if not bool(plot.get("tilled", false)) or bool(plot.get("watered", false)):
        return false
    plot["watered"] = true
    _store_plot(cell, plot)
    return true

func plant(cell: Vector2i, crop: CropDefinition) -> bool:
    if not is_cell_in_farm(cell) or crop == null:
        return false
    var plot: Dictionary = get_plot(cell)
    if not bool(plot.get("tilled", false)) or not String(plot.get("crop_id", "")).is_empty():
        return false
    plot["crop_id"] = String(crop.content_id)
    plot["stage"] = 0
    plot["watered_growth"] = 0
    plot["ready"] = false
    _store_plot(cell, plot)
    return true

func harvest(cell: Vector2i, inventory: InventoryComponent) -> bool:
    return harvest_to_container(cell, inventory) > 0

func harvest_to_container(cell: Vector2i, target: ItemSlotContainerComponent, yield_multiplier: float = 1.0) -> int:
    if target == null or not is_cell_in_farm(cell):
        return 0
    var plot: Dictionary = get_plot(cell)
    if not bool(plot.get("ready", false)):
        return 0
    var crop: CropDefinition = ContentDB.get_definition(StringName(str(plot.get("crop_id", "")))) as CropDefinition
    if crop == null:
        return 0
    var amount: int = crop.harvest_min
    if crop.harvest_max > crop.harvest_min:
        amount = randi_range(crop.harvest_min, crop.harvest_max)
    amount = maxi(1, int(ceil(float(amount) * clampf(yield_multiplier, 0.01, 1.0))))
    var batch: Dictionary = {crop.harvest_item_id: amount}
    if not target.can_add_batch(batch):
        return 0
    var leftovers: Dictionary = target.add_batch(batch)
    if not leftovers.is_empty():
        return 0
    if crop.regrow_watered_days > 0:
        plot["ready"] = false
        plot["watered_growth"] = 0
        plot["stage"] = maxi(crop.growth_stages - 2, 0)
        plot["regrowing"] = true
    else:
        plot.erase("crop_id")
        plot.erase("stage")
        plot.erase("watered_growth")
        plot.erase("ready")
    _store_plot(cell, plot)
    QuestService.notify_event(QuestObjectiveDefinition.Kind.HARVEST_ITEM, crop.harvest_item_id, amount)
    return amount

func export_runtime_state() -> Dictionary:
    return {
        "plots": _plots.duplicate(true),
        "owned_cells": _owned_cells.duplicate(true),
        "last_processed_day": _last_processed_day,
    }

func import_runtime_state(state: Dictionary) -> void:
    var plots_value: Variant = state.get("plots", {})
    _plots = Dictionary(plots_value).duplicate(true) if plots_value is Dictionary else {}
    var owned_value: Variant = state.get("owned_cells", null)
    if owned_value is Dictionary:
        _owned_cells = Dictionary(owned_value).duplicate(true)
        _ownership_initialized = false
        _ensure_starter_ownership()
    else:
        # Old saves did not persist placed plot ownership. Migrate starter plots and
        # preserve any existing cultivated cells that still sit in the build area.
        _owned_cells.clear()
        _ownership_initialized = false
        _ensure_starter_ownership()
        for key: Variant in _plots.keys():
            var parts: PackedStringArray = String(key).split(",")
            if parts.size() == 2:
                var cell := Vector2i(int(parts[0]), int(parts[1]))
                if is_cell_in_build_area(cell):
                    _owned_cells[_cell_key(cell)] = true
    _last_processed_day = int(state.get("last_processed_day", WorldTimeService.get_day()))
    farm_state_changed.emit()

func _on_time_changed(day: int, _hour: int, _minute: int, _total: int) -> void:
    if day <= _last_processed_day:
        return
    while _last_processed_day < day:
        _advance_day()
        _last_processed_day += 1

func _advance_day() -> void:
    var keys: Array = _plots.keys()
    for key_value: Variant in keys:
        var key: String = str(key_value)
        var plot_value: Variant = _plots.get(key, {})
        if not plot_value is Dictionary:
            continue
        var plot: Dictionary = Dictionary(plot_value).duplicate(true)
        var crop_id: StringName = StringName(str(plot.get("crop_id", "")))
        if crop_id != &"":
            var crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
            if crop != null and (not crop.requires_water or bool(plot.get("watered", false))):
                var growth: int = int(plot.get("watered_growth", 0)) + 1
                plot["watered_growth"] = growth
                var stage: int = mini(growth / maxi(crop.watered_days_per_stage, 1), crop.growth_stages - 1)
                if bool(plot.get("regrowing", false)):
                    stage = crop.growth_stages - 1 if growth >= crop.regrow_watered_days else maxi(crop.growth_stages - 2, 0)
                plot["stage"] = stage
                plot["ready"] = stage >= crop.growth_stages - 1
        plot["watered"] = false
        _plots[key] = plot
    farm_state_changed.emit()

func _store_plot(cell: Vector2i, plot: Dictionary) -> void:
    _plots[_cell_key(cell)] = plot.duplicate(true)
    plot_changed.emit(cell, plot.duplicate(true))
    farm_state_changed.emit()

func _get_farm_visual() -> FarmPlotVisual:
    return get_node_or_null(farm_visual_path) as FarmPlotVisual

func _cell_key(cell: Vector2i) -> String:
    return "%d,%d" % [cell.x, cell.y]
