extends Node
class_name FarmInteractionComponent

signal farm_action_performed(action: StringName, cell: Vector2i)
signal farm_action_failed(reason: StringName)

@export var actor_path: NodePath = NodePath("..")
@export var inventory_path: NodePath = NodePath("../InventoryComponent")
@export var hotbar_path: NodePath = NodePath("../HotbarComponent")
@export var facing_source_path: NodePath = NodePath("../AnimationComponent")
@export var reach: float = 88.0

var _actor: Node2D
var _inventory: InventoryComponent
var _hotbar: HotbarComponent
var _facing: ActorAnimationComponent

func _ready() -> void:
    _actor = get_node_or_null(actor_path) as Node2D
    _inventory = get_node_or_null(inventory_path) as InventoryComponent
    _hotbar = get_node_or_null(hotbar_path) as HotbarComponent
    _facing = get_node_or_null(facing_source_path) as ActorAnimationComponent

func try_farm_action() -> bool:
    var farm: FarmPlotSystem = _find_farm_system()
    if farm == null or _actor == null or _hotbar == null or _inventory == null:
        return false
    var cell: Vector2i = get_target_cell(farm)
    if not farm.is_cell_in_farm(cell):
        return false
    if bool(farm.get_plot(cell).get("ready", false)):
        if farm.harvest(cell, _inventory):
            farm_action_performed.emit(&"harvest", cell)
        else:
            farm_action_failed.emit(&"inventory_full")
        return true
    var stack: ItemStack = _hotbar.get_selected_stack()
    if stack == null or stack.is_empty():
        farm_action_failed.emit(&"empty_hotbar_slot")
        return true
    var definition: ContentDefinition = ContentDB.get_definition(stack.item_id)
    var tool: ToolDefinition = definition as ToolDefinition
    if tool != null:
        if tool.tool_tag == &"hoe":
            if farm.till(cell):
                farm_action_performed.emit(&"till", cell)
            else:
                farm_action_failed.emit(&"cannot_till")
            return true
        if tool.tool_tag == &"watering_can":
            if farm.water(cell):
                farm_action_performed.emit(&"water", cell)
            else:
                farm_action_failed.emit(&"cannot_water")
            return true
        # Axe, pickaxe and future gathering tools belong to ToolUseComponent.
        # Returning false prevents farm cells from swallowing their input.
        return false
    var seed: SeedItemDefinition = definition as SeedItemDefinition
    if seed != null:
        var crop: CropDefinition = ContentDB.get_definition(seed.crop_id) as CropDefinition
        if crop != null and farm.plant(cell, crop):
            _hotbar.remove_item(seed.content_id, 1)
            farm_action_performed.emit(&"plant", cell)
        else:
            farm_action_failed.emit(&"cannot_plant")
        return true
    if farm.harvest(cell, _inventory):
        farm_action_performed.emit(&"harvest", cell)
        return true
    farm_action_failed.emit(&"nothing_to_do")
    return true

func _find_farm_system() -> FarmPlotSystem:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return null
    return root.get_node_or_null(^"Systems/FarmPlotSystem") as FarmPlotSystem

func get_target_cell(farm: FarmPlotSystem) -> Vector2i:
    var direction: Vector2 = Vector2.DOWN
    if _facing != null and not _facing.facing_vector.is_zero_approx():
        direction = _facing.facing_vector.normalized()
    return farm.world_to_farm_cell(_actor.global_position + direction * reach)
