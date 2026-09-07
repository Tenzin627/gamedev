extends RegionLocalSystem
class_name RegionPlayerCoordinator

@export var player_node_name: StringName = &"PlayerActor"
@export var hud_node_name: StringName = &"CoreHUD"

var player: PlayerActor = null
var hud: CoreHUD = null

func _on_region_bound() -> void:
    call_deferred("_bind_player_and_hud")

func _bind_player_and_hud() -> void:
    if region_root == null or not is_instance_valid(region_root):
        return
    player = region_root.get_node_or_null(NodePath(String(player_node_name))) as PlayerActor
    hud = region_root.get_node_or_null(NodePath(String(hud_node_name))) as CoreHUD
    if hud != null:
        hud.bind_player(player)
