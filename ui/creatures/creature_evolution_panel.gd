extends PanelContainer
class_name CreatureEvolutionPanel

signal panel_state_changed(is_open: bool)
signal evolution_completed(message: String)

@onready var title_label: Label = $Margin/VBox/Title
@onready var current_label: Label = $Margin/VBox/Current
@onready var options_box: VBoxContainer = $Margin/VBox/Options
@onready var result_label: Label = $Margin/VBox/Result
@onready var close_button: Button = $Margin/VBox/CloseButton

var _model: CreatureCollectionModel = CreatureCollectionModel.new()
var _instance_id: String = ""

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 28)
    LungSaUIStyle.apply_muted(current_label, 13)
    LungSaUIStyle.apply_muted(result_label, 12)
    LungSaUIStyle.apply_button(close_button, false)
    close_button.pressed.connect(close_panel)
    visible = false

func open_for_creature(instance_id: String) -> void:
    _instance_id = instance_id
    result_label.text = ""
    _refresh()
    visible = true
    panel_state_changed.emit(true)
    close_button.grab_focus()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    _instance_id = ""
    panel_state_changed.emit(false)

func _refresh() -> void:
    for child: Node in options_box.get_children():
        child.queue_free()
    var creature: CreatureInstanceData = _model.get_creature(_instance_id)
    if creature == null:
        current_label.text = "Creature unavailable."
        return
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    var species_name: String = String(creature.species_id) if species == null else species.display_name
    title_label.text = "Evolution Preview — %s" % species_name
    current_label.text = "Current: %s • %s • Growth %d • Bond %d • Tendencies A:%d S:%d G:%d" % [species_name, String(creature.life_stage).capitalize(), creature.growth_xp, creature.bond_level, int(creature.evolution_tendencies.get("attack", 0)), int(creature.evolution_tendencies.get("speed", 0)), int(creature.evolution_tendencies.get("guard", 0))]

    var rules: Array[CreatureEvolutionDefinition] = _model.get_all_evolution_rules(_instance_id)
    if rules.is_empty():
        var done_label: Label = Label.new()
        done_label.text = "No further evolution is defined for this creature."
        done_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        LungSaUIStyle.apply_muted(done_label, 13)
        options_box.add_child(done_label)
        return
    var eligible: Array[CreatureEvolutionDefinition] = _model.get_evolution_options(_instance_id)
    for evolution_definition: CreatureEvolutionDefinition in rules:
        var target: CreatureSpeciesDefinition = ContentDB.get_definition(evolution_definition.result_species_id) as CreatureSpeciesDefinition
        var target_name: String = String(evolution_definition.result_species_id) if target == null else target.display_name
        var card: PanelContainer = PanelContainer.new()
        LungSaUIStyle.apply_subpanel(card)
        var box: VBoxContainer = VBoxContainer.new()
        box.add_theme_constant_override(&"separation", 7)
        card.add_child(box)
        var heading: Label = Label.new()
        heading.text = "%s → %s" % [evolution_definition.branch_label, target_name]
        LungSaUIStyle.apply_section_title(heading, 18)
        box.add_child(heading)
        var note: Label = Label.new()
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.text = evolution_definition.preview_note
        LungSaUIStyle.apply_muted(note, 12)
        box.add_child(note)
        var requirement: Label = Label.new()
        requirement.text = _model.get_evolution_requirement_text(creature, evolution_definition)
        LungSaUIStyle.apply_muted(requirement, 12)
        box.add_child(requirement)
        var choose_button: Button = Button.new()
        choose_button.text = "Choose %s" % target_name
        choose_button.disabled = not eligible.has(evolution_definition)
        LungSaUIStyle.apply_button(choose_button, eligible.has(evolution_definition))
        choose_button.pressed.connect(_choose_evolution.bind(evolution_definition.content_id))
        box.add_child(choose_button)
        options_box.add_child(card)

func _choose_evolution(evolution_id: StringName) -> void:
    var result: Dictionary = _model.evolve_creature(_instance_id, evolution_id)
    result_label.text = str(result.get("message", "Evolution complete."))
    if bool(result.get("success", false)):
        evolution_completed.emit(result_label.text)
        _refresh()
