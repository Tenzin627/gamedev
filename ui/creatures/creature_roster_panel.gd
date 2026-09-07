extends PanelContainer
class_name CreatureRosterPanel

signal panel_state_changed(is_open: bool)
signal status_message_requested(message: String)
signal evolution_preview_requested(instance_id: String)
signal loadout_requested(instance_id: String)

@onready var title_label: Label = $Margin/VBox/Title
@onready var party_label: Label = $Margin/VBox/PartyLabel
@onready var hint_label: Label = $Margin/VBox/Hint
@onready var list_box: VBoxContainer = $Margin/VBox/Scroll/List
@onready var close_button: Button = $Margin/VBox/CloseButton

var _model: CreatureCollectionModel = CreatureCollectionModel.new()
var _inventory: InventoryComponent = null

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 28)
    LungSaUIStyle.apply_kicker(party_label)
    LungSaUIStyle.apply_button(close_button, false)
    LungSaUIStyle.apply_muted(hint_label, 11)
    close_button.pressed.connect(close_panel)
    if not GameSession.creature_collection_changed.is_connected(_refresh):
        GameSession.creature_collection_changed.connect(_refresh)
    if not GameSession.party_changed.is_connected(_refresh):
        GameSession.party_changed.connect(_refresh)
    visible = false

func _exit_tree() -> void:
    _disconnect_inventory()
    if GameSession.creature_collection_changed.is_connected(_refresh):
        GameSession.creature_collection_changed.disconnect(_refresh)
    if GameSession.party_changed.is_connected(_refresh):
        GameSession.party_changed.disconnect(_refresh)

func bind_inventory(inventory: InventoryComponent) -> void:
    _disconnect_inventory()
    _inventory = inventory
    if _inventory != null and not _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.connect(_refresh)
    if visible:
        _refresh()

func toggle_panel() -> void:
    if visible:
        close_panel()
    else:
        open_panel()

func open_panel() -> void:
    _refresh()
    visible = true
    panel_state_changed.emit(true)
    close_button.grab_focus()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func _refresh() -> void:
    if list_box == null:
        return
    for child: Node in list_box.get_children():
        child.queue_free()
    var party: Array[CreatureInstanceData] = _model.get_party()
    var party_names: Array[String] = []
    for creature: CreatureInstanceData in party:
        party_names.append(_get_creature_name(creature))
    party_label.text = "Active party %d/3: %s" % [party.size(), ", ".join(party_names) if not party_names.is_empty() else "Empty"]
    var foods: Array[StringName] = _get_available_food_ids()
    hint_label.text = "Food is the primary creature growth input. Feeding adds growth XP, Bond, evolution tendencies, and can unlock species-compatible moves. Available creature foods: %d." % foods.size()
    var all_creatures: Array[CreatureInstanceData] = _model.get_all_creatures()
    if all_creatures.is_empty():
        var empty_label: Label = Label.new()
        empty_label.text = "No bonded creatures yet. Approach a wild creature and use Bond."
        empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        list_box.add_child(empty_label)
        return
    for creature: CreatureInstanceData in all_creatures:
        _add_creature_card(creature, foods)

func _add_creature_card(creature: CreatureInstanceData, foods: Array[StringName]) -> void:
    var panel: PanelContainer = PanelContainer.new()
    LungSaUIStyle.apply_subpanel(panel)
    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)

    var in_party: bool = _model.is_in_party(creature.instance_id)
    var trait_name: String = String(creature.active_trait_id) if creature.active_trait_id != &"" else "No trait"
    var title: Label = Label.new()
    title.text = "%s  •  %s  •  %s  •  %s" % [_get_creature_name(creature), String(creature.life_stage).capitalize(), trait_name, "PARTY" if in_party else "ROSTER"]
    LungSaUIStyle.apply_title(title, 15)
    box.add_child(title)

    var tendency: Dictionary = creature.evolution_tendencies
    var detail: Label = Label.new()
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    LungSaUIStyle.apply_muted(detail, 11)
    detail.text = "Growth XP %d  |  Bond %d  |  Tendencies A:%d S:%d G:%d  |  Moves %d learned / %d equipped" % [
        creature.growth_xp,
        creature.bond_level,
        int(tendency.get("attack", 0)),
        int(tendency.get("speed", 0)),
        int(tendency.get("guard", 0)),
        creature.learned_move_ids.size(),
        creature.equipped_move_ids.size(),
    ]
    box.add_child(detail)

    var actions: HBoxContainer = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 5)
    box.add_child(actions)

    var party_button: Button = Button.new()
    party_button.text = "Remove from Party" if in_party else "Add to Party"
    party_button.disabled = not in_party and _model.get_party().size() >= CreatureCollectionModel.PARTY_SIZE
    LungSaUIStyle.apply_button(party_button, false)
    party_button.pressed.connect(_toggle_party.bind(creature.instance_id))
    actions.add_child(party_button)

    var loadout_button: Button = Button.new()
    loadout_button.text = "Moves & Trait"
    LungSaUIStyle.apply_button(loadout_button, false)
    loadout_button.pressed.connect(_request_loadout.bind(creature.instance_id))
    actions.add_child(loadout_button)

    var evolution_rules: Array[CreatureEvolutionDefinition] = _model.get_all_evolution_rules(creature.instance_id)
    if not evolution_rules.is_empty():
        var evolution_button: Button = Button.new()
        var eligible_count: int = _model.get_evolution_options(creature.instance_id).size()
        evolution_button.text = "Evolution (%d ready)" % eligible_count
        LungSaUIStyle.apply_button(evolution_button, false)
        evolution_button.pressed.connect(_request_evolution_preview.bind(creature.instance_id))
        actions.add_child(evolution_button)

    for food_id: StringName in foods:
        var food: CreatureFoodDefinition = ContentDB.get_definition(food_id) as CreatureFoodDefinition
        if food == null:
            continue
        var food_button: Button = Button.new()
        var quantity: int = CarriedInventoryService.get_total_quantity(_inventory, food_id) if _inventory != null else 0
        food_button.text = "Feed %s ×%d" % [food.display_name, quantity]
        food_button.tooltip_text = _food_tooltip(food)
        food_button.disabled = quantity <= 0
        LungSaUIStyle.apply_button(food_button, false)
        food_button.pressed.connect(_feed_creature.bind(creature.instance_id, food_id))
        actions.add_child(food_button)

    list_box.add_child(panel)

func _request_loadout(instance_id: String) -> void:
    loadout_requested.emit(instance_id)

func _request_evolution_preview(instance_id: String) -> void:
    evolution_preview_requested.emit(instance_id)

func _toggle_party(instance_id: String) -> void:
    if _model.is_in_party(instance_id):
        _model.remove_from_party(instance_id)
    else:
        _model.add_to_party(instance_id)
    _refresh()

func _feed_creature(instance_id: String, food_id: StringName) -> void:
    var result: Dictionary = _model.feed_creature(instance_id, food_id, _inventory)
    var message: String = str(result.get("message", "Feeding complete."))
    var new_moves_variant: Variant = result.get("new_moves", [])
    if bool(result.get("success", false)) and new_moves_variant is Array and not Array(new_moves_variant).is_empty():
        var move_names: Array[String] = []
        for move_variant: Variant in Array(new_moves_variant):
            var move_id: StringName = StringName(str(move_variant))
            var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
            move_names.append(String(move_id) if move_definition == null else move_definition.display_name)
        message += " New move access: %s." % ", ".join(move_names)
    status_message_requested.emit(message)
    _refresh()

func _get_available_food_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    if _inventory == null:
        return result
    for index: int in range(_inventory.get_slot_count()):
        var item_id: StringName = _inventory.get_item_id(index)
        if item_id == &"" or result.has(item_id):
            continue
        if ContentDB.get_definition(item_id) is CreatureFoodDefinition:
            result.append(item_id)
    return result

func _food_tooltip(food: CreatureFoodDefinition) -> String:
    return "+%d Growth XP | +%d Bond | tendencies A:%d S:%d G:%d" % [food.growth_xp, food.bond_growth, food.attack_tendency, food.speed_tendency, food.guard_tendency]

func _disconnect_inventory() -> void:
    if _inventory != null and is_instance_valid(_inventory) and _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.disconnect(_refresh)
    _inventory = null

func _get_creature_name(creature: CreatureInstanceData) -> String:
    if not creature.nickname.is_empty():
        return creature.nickname
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    return String(creature.species_id) if species == null else species.display_name
