extends CanvasLayer
class_name EncyclopediaPanel

signal panel_state_changed(is_open: bool)

@onready var summary_label: Label = $Root/Panel/Margin/VBox/Summary
@onready var tabs: TabContainer = $Root/Panel/Margin/VBox/Tabs
@onready var creatures_text: RichTextLabel = $Root/Panel/Margin/VBox/Tabs/Creatures
@onready var plants_text: RichTextLabel = $Root/Panel/Margin/VBox/Tabs/Plants
@onready var places_text: RichTextLabel = $Root/Panel/Margin/VBox/Tabs/Findings

func _ready() -> void:
    visible = false
    var panel: PanelContainer = $Root/Panel
    var title: Label = $Root/Panel/Margin/VBox/Header/Title
    var close_button: Button = $Root/Panel/Margin/VBox/Header/Close
    LungSaUIStyle.apply_panel(panel, true)
    LungSaUIStyle.apply_title(title, 28)
    LungSaUIStyle.apply_muted(summary_label, 12)
    LungSaUIStyle.apply_button(close_button, false)
    close_button.pressed.connect(close_panel)
    CollectionEncyclopediaService.collection_changed.connect(_refresh)
    GameSession.session_state_changed.connect(_on_session_state_changed)

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    var close_pressed: bool = event.is_action_pressed(&"ui_cancel")
    if InputMap.has_action(&"toggle_encyclopedia"):
        close_pressed = close_pressed or event.is_action_pressed(&"toggle_encyclopedia")
    if close_pressed:
        close_panel()
        _mark_input_handled()

func open_panel() -> void:
    _refresh()
    visible = true
    panel_state_changed.emit(true)

func close_panel() -> void:
    visible = false
    panel_state_changed.emit(false)

func _refresh() -> void:
    var creature_progress: Dictionary = CollectionEncyclopediaService.get_creature_completion()
    var plant_progress: Dictionary = CollectionEncyclopediaService.get_plant_completion()
    summary_label.text = "Creatures %d/%d owned  •  Plants %d/%d found  •  Region findings %d" % [int(creature_progress.get("owned", 0)), int(creature_progress.get("total", 0)), int(plant_progress.get("found", 0)), int(plant_progress.get("total", 0)), _discovery_count()]
    creatures_text.text = _build_creatures()
    plants_text.text = _build_plants()
    places_text.text = _build_places()

func _build_creatures() -> String:
    var lines: Array[String] = []
    for definition: CreatureSpeciesDefinition in CollectionEncyclopediaService.get_creature_species():
        var seen: bool = CollectionEncyclopediaService.is_creature_seen(definition.content_id)
        var owned: bool = CollectionEncyclopediaService.is_creature_owned(definition.content_id)
        if not seen:
            lines.append("[b]???[/b]\nUndiscovered creature.\n")
            continue
        var state: String = "OWNED" if owned else "SEEN"
        lines.append("[b]%s[/b]  [%s]  %s / %s\n%s\nHabitats: %s\n" % [definition.display_name, state, definition.life_stage, definition.archetype, definition.description, _join_names(definition.habitat_tags)])
    return "\n".join(lines)

func _build_plants() -> String:
    var lines: Array[String] = []
    for definition: PlantDefinition in CollectionEncyclopediaService.get_plants():
        if not CollectionEncyclopediaService.is_plant_discovered(definition):
            lines.append("[b]???[/b]\nUndiscovered plant.\n")
            continue
        lines.append("[b]%s[/b]  [FOUND]\n%s\nRegions: %s\n" % [definition.display_name, definition.description, _join_names(definition.region_ids)])
    return "\n".join(lines)

func _build_places() -> String:
    var lines: Array[String] = []
    var discovered: Variant = GameSession.get_value(&"exploration_discoveries", [])
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: DiscoveryDefinition = ContentDB.get_definition(content_id) as DiscoveryDefinition
        if definition == null:
            continue
        var found: bool = discovered is Array and Array(discovered).has(String(content_id))
        lines.append("[b]%s[/b] — %s\n%s\n" % [definition.display_name if found else "???", definition.discovery_kind if found else "Unknown", definition.description if found else "Explore Lung Sa to record this entry."])
    return "\n".join(lines)

func _join_names(ids: Array[StringName]) -> String:
    var values: PackedStringArray = PackedStringArray()
    for value: StringName in ids:
        values.append(String(value).replace("_", " ").replace(".", " › "))
    return ", ".join(values)

func _discovery_count() -> int:
    var value: Variant = GameSession.get_value(&"exploration_discoveries", [])
    return Array(value).size() if value is Array else 0

func _on_session_state_changed(key: StringName, _value: Variant) -> void:
    if visible and (key == &"exploration_discoveries" or key == &"encyclopedia_seen_creatures" or key == &"encyclopedia_owned_creatures" or key == &"encyclopedia_evolved_creatures"):
        _refresh()

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
