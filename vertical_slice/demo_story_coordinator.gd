extends Node

## Canonical slice presentation is driven by authored dialogue/quest content.
## This coordinator now owns only the reusable slice-restart hook; it must not
## inject obsolete prototype debt, quest, or completion copy.

func _ready() -> void:
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)
    call_deferred("_bind_hud")

func _on_location_changed(_region_id: StringName, _zone_id: StringName, _spawn_id: StringName) -> void:
    call_deferred("_bind_hud")

func _bind_hud() -> void:
    var hud: CoreHUD = _get_hud()
    if hud != null and not hud.slice_restart_requested.is_connected(_on_restart_requested):
        hud.slice_restart_requested.connect(_on_restart_requested)

func _on_restart_requested() -> void:
    DemoBootstrap.restart_demo()

func _get_hud() -> CoreHUD:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    return root.get_node_or_null(^"CoreHUD") as CoreHUD if root != null else null
