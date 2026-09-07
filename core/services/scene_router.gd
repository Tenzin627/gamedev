extends Node

signal scene_change_started(scene_path: String, spawn_id: StringName)
signal scene_change_finished(scene_path: String, spawn_id: StringName)
signal location_changed(region_id: StringName, zone_id: StringName, spawn_id: StringName)
signal transition_failed(reason: String)
signal spawn_fallback_used(scene_path: String, requested_spawn_id: StringName, resolved_spawn_id: StringName)

const DEFAULT_SCENE_PATH: String = "res://world/central_basin/zones/demo_farm.tscn"
const FADE_OUT_SECONDS: float = 0.16
const FADE_IN_SECONDS: float = 0.22
const TITLE_HOLD_SECONDS: float = 1.1
const TITLE_FADE_SECONDS: float = 0.28
const TRANSITION_OVERLAY_SCENE: PackedScene = preload("res://ui/transitions/scene_transition_overlay.tscn")

var current_scene_path: String = DEFAULT_SCENE_PATH
var current_region_id: StringName = &""
var current_zone_id: StringName = &""
var current_spawn_id: StringName = &"default"

var pending_spawn_id: StringName = &"default"
var pending_region_id: StringName = &""
var pending_zone_id: StringName = &""

var _transition_in_progress: bool = false
var _tree_was_paused: bool = false
var _transition_overlay: SceneTransitionOverlay = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_transition_overlay()

func is_transition_in_progress() -> bool:
    return _transition_in_progress

func change_scene(scene_path: String, spawn_id: StringName = &"default") -> Error:
    return _change_scene_internal(scene_path, spawn_id, &"", &"")

func travel_to_region(region_id: StringName, spawn_id: StringName = &"") -> Error:
    var definition: RegionDefinition = ContentDB.get_definition(region_id) as RegionDefinition
    if definition == null:
        return _fail_transition("Unknown region definition: %s" % String(region_id), ERR_DOES_NOT_EXIST)
    if definition.default_zone_id != &"":
        return travel_to_zone(definition.default_zone_id, spawn_id)
    var resolved_spawn: StringName = spawn_id if spawn_id != &"" else definition.default_spawn_id
    return _change_scene_internal(definition.scene_path, resolved_spawn, definition.content_id, &"")

func travel_to_zone(zone_id: StringName, spawn_id: StringName = &"") -> Error:
    var definition: ZoneDefinition = get_zone_definition(zone_id)
    if definition == null:
        return _fail_transition("Unknown zone definition: %s" % String(zone_id), ERR_DOES_NOT_EXIST)
    var resolved_spawn: StringName = spawn_id if spawn_id != &"" else definition.default_spawn_id
    return _change_scene_internal(definition.scene_path, resolved_spawn, definition.region_id, definition.content_id)

func get_zone_definition(zone_id: StringName) -> ZoneDefinition:
    return ContentDB.get_definition(zone_id) as ZoneDefinition

func get_region_definition(region_id: StringName) -> RegionDefinition:
    return ContentDB.get_definition(region_id) as RegionDefinition

func capture_current_region_runtime() -> void:
    var region_root: RegionRoot = get_current_region_root()
    if region_root != null:
        region_root.persist_current_runtime_state()

func get_current_region_root() -> RegionRoot:
    if get_tree() == null:
        return null
    for node: Node in get_tree().get_nodes_in_group(&"region_root"):
        if node is RegionRoot:
            var region_root: RegionRoot = node as RegionRoot
            if current_zone_id == &"" or region_root.get_zone_id() == current_zone_id:
                return region_root
    return null

func notify_region_ready(region_root: RegionRoot) -> void:
    if region_root == null:
        return
    current_scene_path = region_root.scene_file_path if not region_root.scene_file_path.is_empty() else current_scene_path
    current_region_id = region_root.get_region_id()
    current_zone_id = region_root.get_zone_id()
    if pending_region_id != &"":
        current_region_id = pending_region_id
    if pending_zone_id != &"":
        current_zone_id = pending_zone_id
    location_changed.emit(current_region_id, current_zone_id, current_spawn_id)

func consume_pending_spawn_id() -> StringName:
    var result: StringName = pending_spawn_id
    if result == &"":
        result = &"default"
    current_spawn_id = result
    pending_spawn_id = &"default"
    pending_region_id = &""
    pending_zone_id = &""
    return result

func restore_saved_location() -> Error:
    if current_scene_path.is_empty():
        return _fail_transition("No saved scene path is available.", ERR_INVALID_DATA)
    return _change_scene_internal(current_scene_path, current_spawn_id, current_region_id, current_zone_id)

func export_state() -> Dictionary:
    return {
        "current_scene_path": current_scene_path,
        "current_region_id": String(current_region_id),
        "current_zone_id": String(current_zone_id),
        "current_spawn_id": String(current_spawn_id),
        "pending_spawn_id": String(pending_spawn_id),
        "pending_region_id": String(pending_region_id),
        "pending_zone_id": String(pending_zone_id),
    }

func import_state(data: Dictionary) -> void:
    current_scene_path = str(data.get("current_scene_path", DEFAULT_SCENE_PATH))
    if current_scene_path.is_empty() or not ResourceLoader.exists(current_scene_path, "PackedScene"):
        current_scene_path = DEFAULT_SCENE_PATH
    current_region_id = StringName(str(data.get("current_region_id", "")))
    current_zone_id = StringName(str(data.get("current_zone_id", "")))
    current_spawn_id = StringName(str(data.get("current_spawn_id", "default")))
    pending_spawn_id = StringName(str(data.get("pending_spawn_id", "default")))
    pending_region_id = StringName(str(data.get("pending_region_id", "")))
    pending_zone_id = StringName(str(data.get("pending_zone_id", "")))

func _change_scene_internal(scene_path: String, spawn_id: StringName, region_id: StringName, zone_id: StringName) -> Error:
    if _transition_in_progress:
        return _fail_transition("A scene transition is already in progress.", ERR_BUSY)
    if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
        return _fail_transition("Scene does not exist: %s" % scene_path, ERR_FILE_NOT_FOUND)

    var requested_spawn: StringName = spawn_id if spawn_id != &"" else &"default"
    var resolved_spawn: StringName = _resolve_destination_spawn(scene_path, requested_spawn, zone_id)

    _transition_in_progress = true
    pending_spawn_id = resolved_spawn
    pending_region_id = region_id
    pending_zone_id = zone_id
    scene_change_started.emit(scene_path, resolved_spawn)
    call_deferred("_perform_scene_change", scene_path, resolved_spawn, region_id, zone_id)
    return OK

func _perform_scene_change(scene_path: String, spawn_id: StringName, region_id: StringName, zone_id: StringName) -> void:
    _ensure_transition_overlay()
    capture_current_region_runtime()
    _lock_transition_input()
    await _fade_to(1.0, FADE_OUT_SECONDS)

    var error: Error = get_tree().change_scene_to_file(scene_path)
    if error != OK:
        _transition_in_progress = false
        await _fade_to(0.0, FADE_IN_SECONDS)
        _unlock_transition_input()
        _hide_transition_overlay()
        _fail_transition("Failed to change scene: %s (%s)" % [scene_path, error_string(error)], error)
        return

    current_scene_path = scene_path
    if region_id != &"":
        current_region_id = region_id
    if zone_id != &"":
        current_zone_id = zone_id

    # Let the new scene enter the tree, RegionRoot announce itself, and PlayerActor
    # consume the validated pending spawn while gameplay remains paused.
    await get_tree().process_frame
    await get_tree().process_frame

    var title: String = _resolve_current_location_title()
    if not title.is_empty():
        _show_title(title)

    await _fade_to(0.0, FADE_IN_SECONDS)
    _transition_in_progress = false
    _unlock_transition_input()
    scene_change_finished.emit(scene_path, spawn_id)

    if not title.is_empty():
        _animate_title_out()
    else:
        _hide_transition_overlay()

func _resolve_destination_spawn(scene_path: String, requested_spawn: StringName, zone_id: StringName) -> StringName:
    var packed: PackedScene = load(scene_path) as PackedScene
    if packed == null:
        return requested_spawn
    var root: Node = packed.instantiate()
    if root == null:
        return requested_spawn

    var spawn_ids: Array[StringName] = []
    _collect_spawn_ids(root, spawn_ids)
    root.free()

    # Non-world scenes (for example battle) do not need spawn markers.
    if spawn_ids.is_empty():
        return requested_spawn
    if requested_spawn in spawn_ids:
        return requested_spawn

    var fallback: StringName = &"default"
    if zone_id != &"":
        var zone: ZoneDefinition = get_zone_definition(zone_id)
        if zone != null and zone.default_spawn_id != &"":
            fallback = zone.default_spawn_id
    if fallback not in spawn_ids:
        fallback = spawn_ids[0]

    push_warning("SceneRouter: Spawn '%s' is missing in %s. Falling back to '%s'." % [String(requested_spawn), scene_path, String(fallback)])
    spawn_fallback_used.emit(scene_path, requested_spawn, fallback)
    return fallback

func _collect_spawn_ids(node: Node, output: Array[StringName]) -> void:
    if node is SpawnPoint2D:
        var spawn: SpawnPoint2D = node as SpawnPoint2D
        if spawn.spawn_id != &"" and spawn.spawn_id not in output:
            output.append(spawn.spawn_id)
    for child: Node in node.get_children():
        _collect_spawn_ids(child, output)

func _resolve_current_location_title() -> String:
    var region_root: RegionRoot = get_current_region_root()
    if region_root == null:
        return ""
    var zone_id: StringName = region_root.get_zone_id()
    var zone: ZoneDefinition = get_zone_definition(zone_id)
    if zone != null and not zone.display_name.is_empty():
        return zone.display_name
    return ""

func _lock_transition_input() -> void:
    if get_tree() == null:
        return
    _tree_was_paused = get_tree().paused
    get_tree().paused = true
    if _transition_overlay != null:
        _transition_overlay.begin_blocking()

func _unlock_transition_input() -> void:
    if get_tree() != null:
        get_tree().paused = _tree_was_paused
    if _transition_overlay != null:
        _transition_overlay.stop_blocking()

func _ensure_transition_overlay() -> void:
    if _transition_overlay != null and is_instance_valid(_transition_overlay):
        return
    _transition_overlay = TRANSITION_OVERLAY_SCENE.instantiate() as SceneTransitionOverlay
    if _transition_overlay == null:
        push_error("SceneRouter: Failed to instantiate transition overlay.")
        return
    add_child(_transition_overlay)

func _fade_to(alpha: float, duration: float) -> void:
    _ensure_transition_overlay()
    if _transition_overlay == null:
        return
    await _transition_overlay.fade_to(alpha, duration)

func _show_title(title: String) -> void:
    _ensure_transition_overlay()
    if _transition_overlay != null:
        _transition_overlay.show_location_title(title)

func _animate_title_out() -> void:
    if _transition_overlay == null:
        return
    _transition_overlay.animate_title_out(TITLE_HOLD_SECONDS, TITLE_FADE_SECONDS)

func _hide_transition_overlay() -> void:
    if _transition_overlay != null:
        _transition_overlay.hide_overlay()

func _fail_transition(message: String, error: Error) -> Error:
    transition_failed.emit(message)
    push_error("SceneRouter: %s" % message)
    return error
