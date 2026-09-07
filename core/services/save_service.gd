extends Node

signal save_completed(slot: int, path: String)
signal load_completed(slot: int, path: String)
signal save_failed(slot: int, message: String)
signal load_failed(slot: int, message: String)

const SAVE_VERSION: int = 3
const MIN_MIGRATABLE_VERSION: int = 2
const SAVE_DIR: String = "user://saves"

func save_slot(slot: int = 0) -> Error:
    var region: RegionRoot = SceneRouter.get_current_region_root()
    if region != null: region.persist_current_runtime_state()
    _ensure_save_dir()
    var payload: SaveGameData = SaveGameData.new()
    payload.save_version = SAVE_VERSION
    payload.profile_id = GameSession.profile_id
    payload.saved_at_unix = int(Time.get_unix_time_from_system())
    payload.session_state = GameSession.export_state()
    payload.world_state = WorldStateService.export_state()
    payload.scene_state = SceneRouter.export_state()

    var path: String = get_slot_path(slot)
    var temp_path: String = "%s.tmp" % path
    var backup_path: String = "%s.bak" % path
    var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        var message: String = "Could not open save path: %s" % path
        save_failed.emit(slot, message)
        push_error(message)
        return FileAccess.get_open_error()
    var serialized: String = JSON.stringify(payload.to_dict(), "  ")
    file.store_string(serialized)
    file.close()
    if not JSON.parse_string(serialized) is Dictionary:
        _remove_if_present(temp_path)
        var validation_message: String = "Generated save data failed validation."
        save_failed.emit(slot, validation_message)
        return ERR_INVALID_DATA
    var absolute_path: String = ProjectSettings.globalize_path(path)
    var absolute_temp: String = ProjectSettings.globalize_path(temp_path)
    var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
    if FileAccess.file_exists(backup_path):
        DirAccess.remove_absolute(absolute_backup)
    if FileAccess.file_exists(path):
        var backup_error: Error = DirAccess.rename_absolute(absolute_path, absolute_backup)
        if backup_error != OK:
            _remove_if_present(temp_path)
            save_failed.emit(slot, "Could not create save backup: %s" % error_string(backup_error))
            return backup_error
    var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_path)
    if replace_error != OK:
        if FileAccess.file_exists(backup_path):
            DirAccess.rename_absolute(absolute_backup, absolute_path)
        _remove_if_present(temp_path)
        save_failed.emit(slot, "Could not finalize save: %s" % error_string(replace_error))
        return replace_error
    save_completed.emit(slot, path)
    return OK

func load_slot(slot: int = 0) -> Error:
    var path: String = get_slot_path(slot)
    var backup_path: String = "%s.bak" % path
    if not FileAccess.file_exists(path) and not FileAccess.file_exists(backup_path):
        var missing_message: String = "Save does not exist: %s" % path
        load_failed.emit(slot, missing_message)
        return ERR_FILE_NOT_FOUND
    var parsed: Variant = _read_save_data(path) if FileAccess.file_exists(path) else null
    if not parsed is Dictionary and FileAccess.file_exists(backup_path):
        parsed = _read_save_data(backup_path)
    if not parsed is Dictionary:
        var parse_message: String = "Save JSON is not a dictionary: %s" % path
        load_failed.emit(slot, parse_message)
        return ERR_PARSE_ERROR

    var data: Dictionary = Dictionary(parsed)
    var version: int = int(data.get("save_version", 0))
    if version < MIN_MIGRATABLE_VERSION or version > SAVE_VERSION:
        var version_message: String = "Unsupported save version %d; supported versions are %d–%d." % [version, MIN_MIGRATABLE_VERSION, SAVE_VERSION]
        load_failed.emit(slot, version_message)
        return ERR_INVALID_DATA
    data = _migrate_save(data, version)

    var payload: SaveGameData = SaveGameData.from_dict(data)
    var old_region: RegionRoot = SceneRouter.get_current_region_root()
    if old_region != null: old_region.persist_runtime_state = false
    GameSession.import_state(payload.session_state)
    WorldStateService.import_state(payload.world_state)
    SceneRouter.import_state(payload.scene_state)
    load_completed.emit(slot, path)
    return OK

func has_slot(slot: int = 0) -> bool:
    var path: String = get_slot_path(slot)
    return FileAccess.file_exists(path) or FileAccess.file_exists("%s.bak" % path)

func delete_slot(slot: int = 0) -> Error:
    var path: String = get_slot_path(slot)
    var result: Error = OK
    if FileAccess.file_exists(path):
        result = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    _remove_if_present("%s.bak" % path)
    _remove_if_present("%s.tmp" % path)
    return result

func get_slot_path(slot: int) -> String:
    return "%s/slot_%02d.json" % [SAVE_DIR, maxi(slot, 0)]

func _ensure_save_dir() -> void:
    var absolute_path: String = ProjectSettings.globalize_path(SAVE_DIR)
    if not DirAccess.dir_exists_absolute(absolute_path):
        DirAccess.make_dir_recursive_absolute(absolute_path)

func _remove_if_present(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _read_save_data(path: String) -> Variant:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed

func _migrate_save(data: Dictionary, from_version: int) -> Dictionary:
    var migrated: Dictionary = data.duplicate(true)
    var version: int = from_version
    while version < SAVE_VERSION:
        match version:
            2:
                # Version 3 formalizes slot-container overflow handling. The serialized
                # shape is unchanged, so migration only advances the schema marker.
                version = 3
            _:
                break
    migrated["save_version"] = version
    return migrated
