extends RegionLocalSystem
class_name ShopCoordinator

var _hud: CoreHUD = null
var _player: PlayerActor = null

func _on_region_bound() -> void:
    call_deferred("_bind_world")

func _bind_world() -> void:
    if region_root == null:
        return
    _hud = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
    _player = region_root.get_node_or_null(^"PlayerActor") as PlayerActor
    for node: Node in get_tree().get_nodes_in_group(&"shop_stall"):
        _bind_stall(node as ShopStall)
    if not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)

func _exit_tree() -> void:
    if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is ShopStall:
        call_deferred("_bind_stall", node as ShopStall)

func _bind_stall(stall: ShopStall) -> void:
    if stall != null and not stall.shop_requested.is_connected(_on_shop_requested):
        stall.shop_requested.connect(_on_shop_requested)

func _on_shop_requested(shop_id: StringName, start_in_sell_mode: bool = false) -> void:
    if _hud != null and _player != null:
        _hud.open_shop(shop_id, _player.inventory_component, start_in_sell_mode)
