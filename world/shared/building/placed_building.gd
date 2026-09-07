extends Node2D
class_name PlacedBuilding

var building_id: StringName = &""
var placement_id: StringName = &""
var footprint_tiles: Vector2i = Vector2i.ONE
var removable: bool = true
var world_texture: Texture2D = null
@onready var visual: Sprite2D = $Visual

func _ready() -> void:
    _refresh_visual()

func configure(definition: BuildingDefinition, stable_id: StringName) -> void:
    if definition == null:
        return
    building_id = definition.content_id
    placement_id = stable_id
    footprint_tiles = definition.footprint_tiles
    removable = definition.removable
    world_texture = definition.world_texture
    _refresh_visual()

func _refresh_visual() -> void:
    if visual == null:
        return
    visual.texture = world_texture
    if world_texture == null:
        push_warning("Building %s has no world_texture; assign one in BuildingDefinition." % String(building_id))
        return
    var size_px: Vector2 = Vector2(footprint_tiles * WorldGrid.TILE_SIZE_PX)
    var target_size: Vector2 = size_px * 1.2
    visual.position = Vector2(0.0, -size_px.y * 0.4)
    var texture_size: Vector2 = world_texture.get_size()
    if texture_size.x > 0.0 and texture_size.y > 0.0:
        visual.scale = Vector2(target_size.x / texture_size.x, target_size.y / texture_size.y)
