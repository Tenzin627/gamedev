extends RegionLocalSystem
class_name CraftingCoordinator

var _hud: CoreHUD = null
var _player: PlayerActor = null

func _on_region_bound() -> void:
    call_deferred("_bind_world")

func _bind_world() -> void:
    if region_root == null:
        return
    _hud = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
    _player = region_root.get_node_or_null(^"PlayerActor") as PlayerActor
    for node: Node in get_tree().get_nodes_in_group(&"crafting_station"):
        _bind_station(node as CraftingStation)
    if not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)

func _exit_tree() -> void:
    if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is CraftingStation:
        call_deferred("_bind_station", node as CraftingStation)

func _bind_station(station: CraftingStation) -> void:
    if station != null and not station.station_requested.is_connected(_on_station_requested):
        station.station_requested.connect(_on_station_requested)

func _on_station_requested(station_tags: Array[StringName], title: String) -> void:
    if _hud != null and _player != null:
        _hud.open_crafting(station_tags, title, _player.inventory_component)
