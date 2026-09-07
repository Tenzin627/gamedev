extends CanvasLayer
class_name FarmAssignmentPanel

@onready var _shade: ColorRect = $Shade
@onready var _panel: PanelContainer = $Panel
@onready var _list: VBoxContainer = $Panel/Margin/Content/Scroll/CreatureList
@onready var _status: Label = $Panel/Margin/Content/Status
var _system: FarmAssignmentSystem
var _hud: CoreHUD

func _ready() -> void:
    LungSaUIStyle.apply_panel(_panel, true)
    LungSaUIStyle.apply_kicker($Panel/Margin/Content/Kicker)
    LungSaUIStyle.apply_title($Panel/Margin/Content/Title, 28)
    LungSaUIStyle.apply_muted(_status, 12)
    LungSaUIStyle.apply_muted($Panel/Margin/Content/Hint, 11)
    LungSaUIStyle.apply_button($Panel/Margin/Content/CloseButton, false)
    $Panel/Margin/Content/CloseButton.pressed.connect(close_panel)
    _panel.visible = false
    _shade.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_farm_creatures"):
        toggle_panel()
        _mark_input_handled()
    elif _panel.visible and event.is_action_pressed("ui_cancel"):
        close_panel()
        _mark_input_handled()

func toggle_panel() -> void:
    if _panel.visible:
        close_panel()
    else:
        open_panel()

func open_panel() -> void:
    _resolve_system()
    _resolve_hud()
    _refresh()
    _shade.visible = true
    _panel.visible = true
    if _hud != null:
        _hud.set_external_modal_blocked(&"farm_assignment", true)
    call_deferred("_focus_default")

func close_panel() -> void:
    if not _panel.visible:
        return
    _panel.visible = false
    _shade.visible = false
    if _hud != null:
        _hud.set_external_modal_blocked(&"farm_assignment", false)

func _resolve_system() -> void:
    var roots: Array[Node] = get_tree().get_nodes_in_group(&"region_root")
    if roots.is_empty():
        _system = null
        return
    _system = (roots[0] as RegionRoot).get_local_system(&"FarmAssignmentSystem") as FarmAssignmentSystem

func _resolve_hud() -> void:
    var roots: Array[Node] = get_tree().get_nodes_in_group(&"region_root")
    if roots.is_empty():
        _hud = null
        return
    _hud = (roots[0] as RegionRoot).get_node_or_null(^"CoreHUD") as CoreHUD

func _refresh() -> void:
    for child: Node in _list.get_children():
        child.queue_free()
    if _system == null:
        _status.text = "Farm crew is unavailable in this area."
        return
    var creatures: Array[CreatureInstanceData] = CreatureCollectionModel.new().get_all_creatures()
    _status.text = "Assigned %d / %d  •  Jobs are automatic  •  Helper harvest/gather output ≈ 40%% of manual work" % [_system.get_assigned_ids().size(), _system.max_assigned_creatures]
    for creature: CreatureInstanceData in creatures:
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
        if species == null:
            continue
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0.0, 54.0)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        var assigned: bool = _system.is_assigned(creature.instance_id)
        var capability_names: PackedStringArray = _get_work_labels(species)
        var capabilities: String = " • ".join(capability_names)
        button.text = "%s   %s\n%s%s" % [species.display_name, String(species.archetype).to_upper(), capabilities, "   • ASSIGNED" if assigned else ""]
        LungSaUIStyle.apply_button(button, assigned)
        button.pressed.connect(_on_creature_pressed.bind(creature.instance_id))
        _list.add_child(button)

func _get_work_labels(species: CreatureSpeciesDefinition) -> PackedStringArray:
    var labels: PackedStringArray = PackedStringArray()
    if species == null:
        return labels
    var profile: FarmWorkProfileDefinition = ContentDB.get_definition(species.farm_work_profile_id) as FarmWorkProfileDefinition
    if profile != null:
        for rule: FarmWorkRule in profile.get_enabled_rules():
            match rule.kind:
                FarmWorkRule.Kind.HARVEST:
                    labels.append("Harvest")
                FarmWorkRule.Kind.WATER:
                    labels.append("Water")
                FarmWorkRule.Kind.PLANT:
                    labels.append("Plant")
                FarmWorkRule.Kind.TILL:
                    labels.append("Till")
                FarmWorkRule.Kind.GATHER_RESOURCE:
                    labels.append("Gather Materials")
        return labels
    labels.append("No farm jobs")
    return labels

func _on_creature_pressed(instance_id: String) -> void:
    if _system != null:
        _system.toggle_assignment(instance_id)
        _refresh()

func _focus_default() -> void:
    for child: Node in _list.get_children():
        if child is Button:
            (child as Button).grab_focus()
            return

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
