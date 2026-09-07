@tool
extends EditorPlugin

const TEMPLATE_ROOT: String = "res://data/templates"
const CONTENT_ROOT: String = "res://data"
const TEMPLATE_INFO: Array[Dictionary] = [
    {"label": "Creature", "file": "creature_template.tres", "prefix": "creature", "folder": "res://data/creatures"},
    {"label": "Creature Evolution", "file": "evolution_template.tres", "prefix": "evolution", "folder": "res://data/evolution"},
    {"label": "Item", "file": "item_template.tres", "prefix": "item", "folder": "res://data/items"},
    {"label": "Crop", "file": "crop_template.tres", "prefix": "crop", "folder": "res://data/farming"},
    {"label": "Recipe", "file": "recipe_template.tres", "prefix": "recipe", "folder": "res://data/recipes"},
    {"label": "NPC", "file": "npc_template.tres", "prefix": "npc", "folder": "res://data/npcs"},
    {"label": "Dialogue", "file": "dialogue_template.tres", "prefix": "dialogue", "folder": "res://data/dialogue"},
    {"label": "Quest", "file": "quest_template.tres", "prefix": "quest", "folder": "res://data/quests"},
    {"label": "Discovery / Finding", "file": "discovery_template.tres", "prefix": "discovery", "folder": "res://data/exploration"},
    {"label": "Shop", "file": "shop_template.tres", "prefix": "shop", "folder": "res://data/shops"},
    {"label": "Region", "file": "region_template.tres", "prefix": "region", "folder": "res://data/regions"},
    {"label": "Zone", "file": "zone_template.tres", "prefix": "zone", "folder": "res://data/regions"},
    {"label": "Habitat / Wild Encounter", "file": "habitat_template.tres", "prefix": "habitat", "folder": "res://data/habitats"},
    {"label": "Building", "file": "building_template.tres", "prefix": "building", "folder": "res://data/building"},
    {"label": "Loot Table", "file": "loot_table_template.tres", "prefix": "loot", "folder": "res://data/gathering"},
    {"label": "Gatherable Resource", "file": "gatherable_resource_template.tres", "prefix": "resource", "folder": "res://data/gathering"},
    {"label": "Move", "file": "move_template.tres", "prefix": "move", "folder": "res://data/moves"},
    {"label": "Trait", "file": "trait_template.tres", "prefix": "trait", "folder": "res://data/traits"},
    {"label": "Farm Work Profile", "file": "farm_work_profile_template.tres", "prefix": "farm_work", "folder": "res://data/farming/work"},
    {"label": "Interaction", "file": "interaction_template.tres", "prefix": "interaction", "folder": "res://data/interactions"},
    {"label": "Story Chain", "file": "story_chain_template.tres", "prefix": "story_chain", "folder": "res://data/story"},
    {"label": "World Reaction", "file": "world_reaction_template.tres", "prefix": "world_reaction", "folder": "res://data/world"},
]

const WORLD_SCENE_INFO: Array[Dictionary] = [
    {"label": "NPC", "scene": "res://world/shared/npcs/npc_actor.tscn", "container": "NPCs"},
    {"label": "Wild Habitat", "scene": "res://world/shared/habitats/habitat_area_2d.tscn", "container": "Habitats"},
    {"label": "Generic Interactable", "scene": "res://world/shared/interactions/data_interactable.tscn", "container": "WorldObjects"},
    {"label": "Shop Stall", "scene": "res://world/shared/shops/shop_stall.tscn", "container": "WorldObjects"},
    {"label": "Crafting / Cooking Station", "scene": "res://world/shared/crafting/crafting_station.tscn", "container": "WorldObjects"},
    {"label": "Discovery Landmark", "scene": "res://world/shared/exploration/discovery_landmark.tscn", "container": "WorldObjects"},
    {"label": "Waymark", "scene": "res://world/shared/waymarks/waymark_point_2d.tscn", "container": "Waymarks"},
    {"label": "Zone Entrance", "scene": "res://world/shared/transitions/zone_entrance_2d.tscn", "container": "Entrances"},
    {"label": "Spawn Point", "scene": "res://world/shared/spawn_point_2d.tscn", "container": "SpawnPoints"},
]

var _dock: ScrollContainer = null
var _dock_content: VBoxContainer = null
var _type_picker: OptionButton = null
var _world_picker: OptionButton = null
var _save_dialog: EditorFileDialog = null
var _duplicate_dialog: EditorFileDialog = null
var _delete_dialog: ConfirmationDialog = null
var _status: Label = null

func _enter_tree() -> void:
    _build_dock()
    add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)

func _exit_tree() -> void:
    if _dock != null:
        remove_control_from_docks(_dock)
        _dock.queue_free()
    _dock = null
    for dialog: Window in [_save_dialog, _duplicate_dialog, _delete_dialog]:
        if dialog != null:
            dialog.queue_free()
    _save_dialog = null
    _duplicate_dialog = null
    _delete_dialog = null

func _build_dock() -> void:
    _dock = ScrollContainer.new()
    _dock.name = "Lung Sa Designer"
    _dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _dock.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _dock.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

    _dock_content = VBoxContainer.new()
    _dock_content.name = "DesignerTools"
    _dock_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _dock.add_child(_dock_content)

    var title: Label = Label.new()
    title.text = "Lung Sa Designer"
    title.add_theme_font_size_override("font_size", 18)
    _dock_content.add_child(title)

    var help: Label = Label.new()
    help.text = "Create content, place reusable scenes, and jump to designer-owned layers."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.custom_minimum_size = Vector2(0, 0)
    _dock_content.add_child(help)

    _add_section_label("CREATE CONTENT")
    _type_picker = OptionButton.new()
    _type_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for info: Dictionary in TEMPLATE_INFO:
        _type_picker.add_item(str(info.get("label", "Content")))
    _dock_content.add_child(_type_picker)
    _add_dock_button("Create from Preset…", _request_create)
    _add_dock_button("Create NPC + Dialogue + Quest", _create_npc_story_bundle)
    _add_dock_button("Create Region + Zone + Story", _create_region_story_bundle)

    _add_section_label("SELECTED CONTENT")
    _add_dock_button("Duplicate Selected…", _request_duplicate_selected)
    _add_dock_button("Show Dependencies", _show_selected_dependencies)
    _add_dock_button("Safe Delete Selected…", _request_safe_delete_selected)
    _add_dock_button("Open Content Folder", _open_selected_content_folder)

    _add_section_label("PLACE WORLD OBJECT")
    _world_picker = OptionButton.new()
    _world_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for info: Dictionary in WORLD_SCENE_INFO:
        _world_picker.add_item(str(info.get("label", "World Object")))
    _dock_content.add_child(_world_picker)
    _add_dock_button("Add to Current Scene", _place_world_object)

    _add_section_label("PAINT WORLD CONTENT")
    _add_dock_button("Forage Layer", _select_tile_layer.bind(&"Forage"))
    _add_dock_button("Resource Layer", _select_tile_layer.bind(&"ResourceTiles"))
    _add_dock_button("Static Props Layer", _select_tile_layer.bind(&"StaticProps"))

    _add_section_label("DESIGNER VISIBILITY")
    _add_dock_button("Farm", _select_named_node.bind(&"Environment/HomeFarmPlots"))
    _add_dock_button("First Habitat", _select_first_child.bind(&"Habitats"))

    _add_section_label("CHECK")
    _add_dock_button("Validate Content", _validate_content_files)
    _add_dock_button("Play-test Current Scene", _playtest_current_scene)
    _add_dock_button("Open Test Scenes Folder", _open_tests_folder)

    _status = Label.new()
    _status.text = "Ready."
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _dock_content.add_child(_status)

func _add_section_label(text: String) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 8.0
    _dock_content.add_child(spacer)
    var label := Label.new()
    label.text = text
    _dock_content.add_child(label)

func _add_dock_button(text: String, callable: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callable)
    _dock_content.add_child(button)

func _request_create() -> void:
    if _type_picker == null:
        return
    if _save_dialog == null:
        _save_dialog = EditorFileDialog.new()
        _save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
        _save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
        _save_dialog.filters = PackedStringArray(["*.tres ; Lung Sa Content Resource"])
        _save_dialog.file_selected.connect(_create_from_selected_template)
        get_editor_interface().get_base_control().add_child(_save_dialog)
    var info: Dictionary = TEMPLATE_INFO[_type_picker.selected]
    _save_dialog.current_file = "%s_new.tres" % str(info.get("prefix", "content"))
    _save_dialog.current_dir = str(info.get("folder", CONTENT_ROOT))
    _save_dialog.popup_centered_ratio(0.7)

func _create_from_selected_template(path: String) -> void:
    var info: Dictionary = TEMPLATE_INFO[_type_picker.selected]
    var template_path: String = TEMPLATE_ROOT.path_join(str(info.get("file", "")))
    var template: Resource = ResourceLoader.load(template_path)
    if template == null:
        _set_status("Template missing: %s" % template_path)
        return
    var created: Resource = template.duplicate(true)
    if created is ContentDefinition:
        var definition: ContentDefinition = created as ContentDefinition
        var basename: String = path.get_file().get_basename().to_snake_case()
        var prefix: String = str(info.get("prefix", "content"))
        definition.content_id = _make_unique_content_id(prefix, basename, path)
        definition.display_name = basename.replace("_", " ").capitalize()
    var error: Error = ResourceSaver.save(created, path)
    if error != OK:
        _set_status("Could not save resource: %s" % error_string(error))
        return
    get_editor_interface().get_resource_filesystem().scan()
    get_editor_interface().edit_resource(created)
    _set_status("Created %s. Fill its Inspector fields; ContentDB will discover it automatically." % path)

func _request_duplicate_selected() -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null:
        _set_status("Select a content Resource in the FileSystem or Inspector first.")
        return
    if _duplicate_dialog == null:
        _duplicate_dialog = EditorFileDialog.new()
        _duplicate_dialog.access = EditorFileDialog.ACCESS_RESOURCES
        _duplicate_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
        _duplicate_dialog.filters = PackedStringArray(["*.tres ; Lung Sa Content Resource"])
        _duplicate_dialog.file_selected.connect(_duplicate_selected_to)
        get_editor_interface().get_base_control().add_child(_duplicate_dialog)
    _duplicate_dialog.current_dir = selected.resource_path.get_base_dir()
    _duplicate_dialog.current_file = "%s_copy.tres" % selected.resource_path.get_file().get_basename()
    _duplicate_dialog.popup_centered_ratio(0.7)

func _duplicate_selected_to(path: String) -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null:
        _set_status("The selected resource is no longer available.")
        return
    var duplicate: ContentDefinition = selected.duplicate(true) as ContentDefinition
    var prefix: String = String(selected.content_id).get_slice(".", 0)
    var basename: String = path.get_file().get_basename().to_snake_case()
    duplicate.content_id = _make_unique_content_id(prefix, basename, path)
    duplicate.display_name = "%s Copy" % selected.display_name
    var error: Error = ResourceSaver.save(duplicate, path)
    if error != OK:
        _set_status("Duplicate failed: %s" % error_string(error))
        return
    get_editor_interface().get_resource_filesystem().scan()
    get_editor_interface().edit_resource(duplicate)
    _set_status("Duplicated safely as %s." % path)

func _show_selected_dependencies() -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null:
        _set_status("Select a content Resource first.")
        return
    var dependencies: PackedStringArray = _find_dependencies(selected)
    if dependencies.is_empty():
        _set_status("No references found. This resource is currently safe to remove.")
        return
    _set_status("Used by %d file(s). See Output for the complete list." % dependencies.size())
    print("Lung Sa dependencies for %s:" % selected.resource_path)
    for dependency: String in dependencies:
        print("  - %s" % dependency)

func _request_safe_delete_selected() -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null:
        _set_status("Select a content Resource first.")
        return
    if not selected.resource_path.begins_with(CONTENT_ROOT + "/") or selected.resource_path.begins_with(TEMPLATE_ROOT + "/"):
        _set_status("Safe Delete only removes authored content under data/, never templates.")
        return
    var dependencies: PackedStringArray = _find_dependencies(selected)
    if not dependencies.is_empty():
        _set_status("Delete blocked: %d file(s) still reference this content. Use Show Dependencies." % dependencies.size())
        return
    if _delete_dialog == null:
        _delete_dialog = ConfirmationDialog.new()
        _delete_dialog.title = "Safe Delete Content"
        _delete_dialog.confirmed.connect(_delete_selected_content)
        get_editor_interface().get_base_control().add_child(_delete_dialog)
    _delete_dialog.dialog_text = "Delete %s?\n\nNo project references were found." % selected.resource_path
    _delete_dialog.popup_centered()

func _delete_selected_content() -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null or selected.resource_path.is_empty() or selected.resource_path.begins_with(TEMPLATE_ROOT + "/"):
        _set_status("Delete canceled: resource is no longer selected.")
        return
    if not _find_dependencies(selected).is_empty():
        _set_status("Delete canceled: a new dependency was found.")
        return
    var path: String = selected.resource_path
    var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    if error != OK:
        _set_status("Delete failed: %s" % error_string(error))
        return
    get_editor_interface().get_resource_filesystem().scan()
    _set_status("Deleted unused content: %s" % path)

func _get_selected_content() -> ContentDefinition:
    var edited: Object = get_editor_interface().get_inspector().get_edited_object()
    return edited as ContentDefinition

func _find_dependencies(definition: ContentDefinition) -> PackedStringArray:
    var result: PackedStringArray = PackedStringArray()
    if definition == null:
        return result
    var paths: Array[String] = []
    _collect_project_text_files("res://", paths)
    var id_text: String = String(definition.content_id)
    for path: String in paths:
        if path == definition.resource_path or path.begins_with(TEMPLATE_ROOT + "/"):
            continue
        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null:
            continue
        var text: String = file.get_as_text()
        file.close()
        if (not id_text.is_empty() and id_text in text) or definition.resource_path in text:
            result.append(path)
    return result

func _collect_project_text_files(base_path: String, out_paths: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(base_path)
    if directory == null:
        return
    directory.list_dir_begin()
    var file_name: String = directory.get_next()
    while not file_name.is_empty():
        if not file_name.begins_with("."):
            var path: String = base_path.path_join(file_name)
            if directory.current_is_dir():
                _collect_project_text_files(path, out_paths)
            elif file_name.get_extension().to_lower() in ["tres", "tscn", "gd", "godot"]:
                out_paths.append(path)
        file_name = directory.get_next()
    directory.list_dir_end()

func _make_unique_content_id(prefix: String, basename: String, destination_path: String = "") -> StringName:
    var base_id: String = "%s.%s" % [prefix, basename]
    var candidate: String = base_id
    var suffix: int = 2
    while _content_id_exists(candidate, destination_path):
        candidate = "%s_%d" % [base_id, suffix]
        suffix += 1
    return StringName(candidate)

func _content_id_exists(candidate: String, ignored_path: String = "") -> bool:
    var paths: Array[String] = []
    _collect_tres(CONTENT_ROOT, paths)
    for path: String in paths:
        if path == ignored_path or path.begins_with(TEMPLATE_ROOT + "/"):
            continue
        var resource: Resource = ResourceLoader.load(path)
        if resource is ContentDefinition and String((resource as ContentDefinition).content_id) == candidate:
            return true
    return false

func _create_npc_story_bundle() -> void:
    var slug: String = "new_story_%d" % (int(Time.get_unix_time_from_system()) % 100000)
    var dialogue: DialogueDefinition = _create_bundle_resource("dialogue_template.tres", "dialogue", "res://data/dialogue", slug, "New Story Dialogue") as DialogueDefinition
    var quest: QuestDefinition = _create_bundle_resource("quest_template.tres", "quest", "res://data/quests", slug, "New Story Quest") as QuestDefinition
    var npc: NPCDefinition = _create_bundle_resource("npc_template.tres", "npc", "res://data/npcs", slug, "New Story NPC") as NPCDefinition
    if dialogue == null or quest == null or npc == null:
        _set_status("Bundle creation failed. Check Output and remove any incomplete files.")
        return
    npc.default_dialogue_id = dialogue.content_id
    ResourceSaver.save(npc, npc.resource_path)
    get_editor_interface().get_resource_filesystem().scan()
    get_editor_interface().edit_resource(npc)
    _set_status("Created linked NPC + Dialogue + Quest. Edit the NPC now, then place it in a zone.")

func _create_region_story_bundle() -> void:
    var slug: String = "new_region_%d" % (int(Time.get_unix_time_from_system()) % 100000)
    var region: RegionDefinition = _create_bundle_resource("region_template.tres", "region", "res://data/regions", slug, "New Region") as RegionDefinition
    var zone: ZoneDefinition = _create_bundle_resource("zone_template.tres", "zone", "res://data/regions", slug, "New Zone") as ZoneDefinition
    var story: StoryChainDefinition = _create_bundle_resource("story_chain_template.tres", "story_chain", "res://data/story", slug, "New Region Story") as StoryChainDefinition
    if region == null or zone == null or story == null:
        _set_status("Region bundle creation failed. Check Output and remove any incomplete files.")
        return
    zone.region_id = region.content_id
    region.default_zone_id = zone.content_id
    region.zone_ids = [zone.content_id]
    story.region_id = region.content_id
    ResourceSaver.save(zone, zone.resource_path)
    ResourceSaver.save(region, region.resource_path)
    ResourceSaver.save(story, story.resource_path)
    get_editor_interface().get_resource_filesystem().scan()
    get_editor_interface().edit_resource(region)
    _set_status("Created linked Region + Zone + Story. Assign scene paths and story steps in Inspector.")

func _create_bundle_resource(template_file: String, prefix: String, folder: String, slug: String, display_name: String) -> ContentDefinition:
    var template: Resource = ResourceLoader.load(TEMPLATE_ROOT.path_join(template_file))
    if not template is ContentDefinition:
        push_warning("Lung Sa Designer: bundle template missing: %s" % template_file)
        return null
    var resource: ContentDefinition = template.duplicate(true) as ContentDefinition
    var path: String = _unique_resource_path(folder.path_join("%s_%s.tres" % [slug, prefix]))
    resource.content_id = _make_unique_content_id(prefix, slug, path)
    resource.display_name = display_name
    var error: Error = ResourceSaver.save(resource, path)
    if error != OK:
        push_warning("Lung Sa Designer: could not save %s: %s" % [path, error_string(error)])
        return null
    return resource

func _unique_resource_path(base_path: String) -> String:
    if not ResourceLoader.exists(base_path):
        return base_path
    var directory: String = base_path.get_base_dir()
    var basename: String = base_path.get_file().get_basename()
    var suffix: int = 2
    var candidate: String = directory.path_join("%s_%d.tres" % [basename, suffix])
    while ResourceLoader.exists(candidate):
        suffix += 1
        candidate = directory.path_join("%s_%d.tres" % [basename, suffix])
    return candidate

func _open_selected_content_folder() -> void:
    var selected: ContentDefinition = _get_selected_content()
    if selected == null:
        _set_status("Select a content Resource first.")
        return
    get_editor_interface().get_file_system_dock().navigate_to_path(selected.resource_path.get_base_dir())
    _set_status("Opened %s." % selected.resource_path.get_base_dir())

func _playtest_current_scene() -> void:
    if get_editor_interface().get_edited_scene_root() == null:
        _set_status("Open a scene before starting a focused play-test.")
        return
    get_editor_interface().play_current_scene()
    _set_status("Started the current scene. Stop with F8.")

func _open_tests_folder() -> void:
    get_editor_interface().get_file_system_dock().navigate_to_path("res://tests")
    _set_status("Open a test scene and use Play-test Current Scene.")

func _place_world_object() -> void:
    if _world_picker == null:
        return
    var edited_root: Node = get_editor_interface().get_edited_scene_root()
    if edited_root == null:
        _set_status("Open a world scene first, then add the object.")
        return
    var info: Dictionary = WORLD_SCENE_INFO[_world_picker.selected]
    var scene_path: String = str(info.get("scene", ""))
    var packed: PackedScene = ResourceLoader.load(scene_path) as PackedScene
    if packed == null:
        _set_status("Reusable scene missing: %s" % scene_path)
        return
    var node: Node = packed.instantiate()
    var parent: Node = edited_root.get_node_or_null(NodePath(str(info.get("container", ""))))
    if parent == null:
        parent = edited_root
    node.name = str(info.get("label", "WorldObject")).to_pascal_case()
    var undo_redo: EditorUndoRedoManager = get_undo_redo()
    undo_redo.create_action("Add Lung Sa %s" % str(info.get("label", "World Object")))
    undo_redo.add_do_method(parent, "add_child", node, true)
    undo_redo.add_do_method(node, "set_owner", edited_root)
    undo_redo.add_do_reference(node)
    undo_redo.add_undo_method(parent, "remove_child", node)
    undo_redo.commit_action()
    get_editor_interface().get_selection().clear()
    get_editor_interface().get_selection().add_node(node)
    _set_status("Added %s. Set its IDs/Resource fields in Inspector, position it, then save the scene." % str(info.get("label", "world object")))


func _select_tile_layer(layer_name: StringName) -> void:
    var edited_root: Node = get_editor_interface().get_edited_scene_root()
    if edited_root == null:
        _set_status("Open a region/zone scene first.")
        return
    var layer: Node = edited_root.get_node_or_null(NodePath("TileLayers/%s" % String(layer_name)))
    if layer == null:
        _set_status("This scene has no %s TileMapLayer." % String(layer_name))
        return
    get_editor_interface().get_selection().clear()
    get_editor_interface().get_selection().add_node(layer)
    _set_status("Selected %s. Paint content with the TileMap palette. Select the tile in the TileSet editor and set its Custom Data content_id/content_kind; no numeric catalog mapping is needed." % String(layer_name))

func _validate_content_files() -> void:
    var paths: Array[String] = []
    _collect_tres(CONTENT_ROOT, paths)
    var seen_ids: Dictionary = {}
    var problems: PackedStringArray = PackedStringArray()
    var count: int = 0
    for path: String in paths:
        if path.begins_with(TEMPLATE_ROOT + "/"):
            continue
        var resource: Resource = ResourceLoader.load(path)
        if not resource is ContentDefinition:
            continue
        count += 1
        var definition: ContentDefinition = resource as ContentDefinition
        if definition.content_id == &"":
            problems.append("Missing content_id: %s" % path)
        elif seen_ids.has(definition.content_id):
            problems.append("Duplicate %s: %s and %s" % [String(definition.content_id), str(seen_ids[definition.content_id]), path])
        else:
            seen_ids[definition.content_id] = path
        if definition.display_name.strip_edges().is_empty():
            problems.append("Missing display_name: %s" % path)
        for definition_error: String in definition.validate_definition():
            problems.append("%s — %s" % [path, definition_error])
    if problems.is_empty():
        _set_status("Validation passed: %d auto-registered content resources." % count)
        print("Lung Sa Designer validation passed: %d content resources." % count)
    else:
        _set_status("Validation found %d issue(s). See Output." % problems.size())
        for problem: String in problems:
            push_warning("Lung Sa Designer: %s" % problem)

func _collect_tres(base_path: String, out_paths: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(base_path)
    if directory == null:
        return
    directory.list_dir_begin()
    var file_name: String = directory.get_next()
    while not file_name.is_empty():
        if not file_name.begins_with("."):
            var path: String = base_path.path_join(file_name)
            if directory.current_is_dir():
                _collect_tres(path, out_paths)
            elif file_name.get_extension().to_lower() == "tres":
                out_paths.append(path)
        file_name = directory.get_next()
    directory.list_dir_end()

func _set_status(text: String) -> void:
    if _status != null:
        _status.text = text

func _select_named_node(node_path: StringName) -> void:
    var edited_root: Node = get_editor_interface().get_edited_scene_root()
    if edited_root == null:
        _set_status("Open a zone scene first.")
        return
    var node: Node = edited_root.get_node_or_null(NodePath(String(node_path)))
    if node == null:
        _set_status("This scene does not contain %s." % String(node_path))
        return
    get_editor_interface().get_selection().clear()
    get_editor_interface().get_selection().add_node(node)
    _set_status("Selected %s. Its designer-facing visuals should be visible directly in the 2D editor." % node.name)

func _select_first_child(container_path: StringName) -> void:
    var edited_root: Node = get_editor_interface().get_edited_scene_root()
    if edited_root == null:
        _set_status("Open a zone scene first.")
        return
    var container: Node = edited_root.get_node_or_null(NodePath(String(container_path)))
    if container == null or container.get_child_count() == 0:
        _set_status("No authored objects under %s." % String(container_path))
        return
    var node: Node = container.get_child(0)
    get_editor_interface().get_selection().clear()
    get_editor_interface().get_selection().add_node(node)
    _set_status("Selected %s. Resize/edit it in Inspector and the 2D editor." % node.name)
