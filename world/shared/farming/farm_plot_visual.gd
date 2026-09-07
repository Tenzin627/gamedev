@tool
extends Node2D
class_name FarmPlotVisual

## Designer-authored farm space.
## - Paint FarmBuildArea to define where farm plots MAY be placed.
## - Paint StarterPlots to define plots owned in a fresh game.
## Runtime owns FarmOwnedPlots/FarmSoil/FarmCrops.
const SOURCE_UNTILLED: int = 0
const SOURCE_TILLED: int = 1
const SOURCE_WATERED: int = 2
@export var farm_system_path: NodePath = NodePath("../../Systems/FarmPlotSystem")

@onready var farm_build_area: TileMapLayer = $FarmBuildArea
@onready var starter_plots: TileMapLayer = $StarterPlots
@onready var farm_owned_plots: TileMapLayer = $FarmOwnedPlots
@onready var farm_soil: TileMapLayer = $FarmSoil
@onready var farm_crops: TileMapLayer = $FarmCrops
var _farm: FarmPlotSystem

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    # BuildArea and StarterPlots are authoring guides. Runtime shows only owned plots.
    farm_build_area.visible = false
    starter_plots.visible = false
    _farm = get_node_or_null(farm_system_path) as FarmPlotSystem
    if _farm == null:
        push_error("FarmPlotVisual could not find FarmPlotSystem at %s" % farm_system_path)
        return
    if not _farm.farm_state_changed.is_connected(refresh_runtime_layers):
        _farm.farm_state_changed.connect(refresh_runtime_layers)
    refresh_runtime_layers()

func refresh_runtime_layers() -> void:
    if _farm == null:
        return
    farm_owned_plots.clear()
    farm_soil.clear()
    farm_crops.clear()
    for cell: Vector2i in _farm.get_owned_cells():
        farm_owned_plots.set_cell(cell, SOURCE_UNTILLED, Vector2i.ZERO)
        var plot: Dictionary = _farm.get_plot(cell)
        if bool(plot.get("tilled", false)):
            var soil_source: int = SOURCE_WATERED if bool(plot.get("watered", false)) else SOURCE_TILLED
            farm_soil.set_cell(cell, soil_source, Vector2i.ZERO)
        var crop_id: StringName = StringName(str(plot.get("crop_id", "")))
        if crop_id != &"":
            var crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
            if crop != null:
                var stage: int = int(plot.get("stage", 0))
                var crop_source: int = crop.get_farm_tile_source(stage, bool(plot.get("ready", false)))
                if crop_source >= 0:
                    farm_crops.set_cell(cell, crop_source, Vector2i.ZERO)

func get_build_area_cells() -> Array[Vector2i]:
    return farm_build_area.get_used_cells() if farm_build_area != null else []

func is_build_area_cell(cell: Vector2i) -> bool:
    return farm_build_area != null and farm_build_area.get_cell_source_id(cell) >= 0

func get_starter_cells() -> Array[Vector2i]:
    return starter_plots.get_used_cells() if starter_plots != null else []

func get_farm_layers() -> Array[TileMapLayer]:
    return [farm_build_area, starter_plots, farm_owned_plots, farm_soil, farm_crops]
