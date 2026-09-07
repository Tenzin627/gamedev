extends RefCounted
class_name SaveGameData

var save_version: int = 2
var profile_id: String = "default"
var saved_at_unix: int = 0
var session_state: Dictionary = {}
var world_state: Dictionary = {}
var scene_state: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "save_version": save_version,
        "profile_id": profile_id,
        "saved_at_unix": saved_at_unix,
        "session_state": session_state.duplicate(true),
        "world_state": world_state.duplicate(true),
        "scene_state": scene_state.duplicate(true),
    }

static func from_dict(data: Dictionary) -> SaveGameData:
    var result: SaveGameData = SaveGameData.new()
    result.save_version = int(data.get("save_version", 2))
    result.profile_id = str(data.get("profile_id", "default"))
    result.saved_at_unix = int(data.get("saved_at_unix", 0))
    result.session_state = Dictionary(data.get("session_state", {})).duplicate(true)
    result.world_state = Dictionary(data.get("world_state", {})).duplicate(true)
    result.scene_state = Dictionary(data.get("scene_state", {})).duplicate(true)
    return result
