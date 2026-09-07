extends Node

signal content_rebuilt(definition_count: int, error_count: int)

const CONTENT_ROOT: String = "res://data"
const TEMPLATE_DIR: String = "res://data/templates"
const ACTIVE_PROFILE_PATH: String = "res://data/profiles/active_game_profile.tres"

var _definitions: Dictionary = {}
var _definition_sources: Dictionary = {}
var _last_errors: PackedStringArray = PackedStringArray()

func _ready() -> void:
    rebuild()

func rebuild() -> PackedStringArray:
    _definitions.clear()
    _definition_sources.clear()
    _last_errors = PackedStringArray()

    var paths: Array[String] = []
    _collect_tres_paths(CONTENT_ROOT, paths)
    paths.sort()

    # Designer-first registration: every standalone ContentDefinition under
    # res://data is discovered automatically. Catalogs are optional grouping
    # resources, not a required registration step.
    for path: String in paths:
        if path.begins_with(TEMPLATE_DIR + "/"):
            continue
        var loaded: Resource = ResourceLoader.load(path)
        if loaded == null:
            _last_errors.append("Failed to load resource: %s" % path)
            continue
        if loaded is ContentDefinition:
            _register_definition(loaded as ContentDefinition, path)

    # Cross-reference validation happens only after the complete direct registry exists.
    var ids: Array[StringName] = get_all_ids()
    for content_id: StringName in ids:
        var definition: ContentDefinition = get_definition(content_id)
        if definition == null:
            continue
        var source_path: String = str(_definition_sources.get(content_id, "<unknown resource>"))
        for definition_error: String in definition.validate_definition():
            _last_errors.append("%s -> %s: %s" % [source_path, String(content_id), definition_error])

    content_rebuilt.emit(_definitions.size(), _last_errors.size())
    if not _last_errors.is_empty():
        push_warning("ContentDB rebuilt with %d error(s). See validate_all()." % _last_errors.size())
    return _last_errors.duplicate()

func _register_definition(definition: ContentDefinition, path: String) -> void:
    if definition == null or definition.content_id == &"":
        return
    if _definitions.has(definition.content_id):
        var first_source: String = str(_definition_sources.get(definition.content_id, "<unknown resource>"))
        _last_errors.append("Duplicate content_id %s in %s and %s" % [String(definition.content_id), first_source, path])
        return
    _definitions[definition.content_id] = definition
    _definition_sources[definition.content_id] = path

func get_definition(content_id: StringName) -> ContentDefinition:
    return _definitions.get(content_id, null) as ContentDefinition

func has_definition(content_id: StringName) -> bool:
    return _definitions.has(content_id)

func get_all_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _definitions.keys():
        result.append(StringName(str(key)))
    result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
    return result

func get_all_definitions() -> Array[ContentDefinition]:
    var result: Array[ContentDefinition] = []
    for content_id: StringName in get_all_ids():
        var definition: ContentDefinition = get_definition(content_id)
        if definition != null:
            result.append(definition)
    return result

func get_definitions_with_tag(tag: StringName) -> Array[ContentDefinition]:
    var result: Array[ContentDefinition] = []
    for definition: ContentDefinition in get_all_definitions():
        if definition.tags.has(tag):
            result.append(definition)
    return result

func get_count() -> int:
    return _definitions.size()

func get_active_profile() -> GameProfileDefinition:
    if not ResourceLoader.exists(ACTIVE_PROFILE_PATH):
        return null
    return ResourceLoader.load(ACTIVE_PROFILE_PATH) as GameProfileDefinition

func validate_all() -> PackedStringArray:
    rebuild()
    return _last_errors.duplicate()

func get_last_errors() -> PackedStringArray:
    return _last_errors.duplicate()

func _collect_tres_paths(base_path: String, out_paths: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(base_path)
    if directory == null:
        if base_path == CONTENT_ROOT:
            _last_errors.append("Content directory missing: %s" % base_path)
        return
    directory.list_dir_begin()
    var file_name: String = directory.get_next()
    while not file_name.is_empty():
        if file_name.begins_with("."):
            file_name = directory.get_next()
            continue
        var full_path: String = base_path.path_join(file_name)
        if directory.current_is_dir():
            _collect_tres_paths(full_path, out_paths)
        elif file_name.get_extension().to_lower() == "tres":
            out_paths.append(full_path)
        file_name = directory.get_next()
    directory.list_dir_end()
