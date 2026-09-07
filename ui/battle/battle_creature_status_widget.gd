extends PanelContainer
class_name BattleCreatureStatusWidget

@export var side_label: String = "ACTIVE"

@onready var side_label_node: Label = $Margin/VBox/Header/Side
@onready var name_label: Label = $Margin/VBox/Header/Name
@onready var archetype_label: Label = $Margin/VBox/Header/Archetype
@onready var stage_label: Label = $Margin/VBox/Meta/Stage
@onready var trait_label: Label = $Margin/VBox/Meta/Trait
@onready var hp_bar: ProgressBar = $Margin/VBox/HPRow/HPBar
@onready var hp_label: Label = $Margin/VBox/HPRow/HP
@onready var status_label: Label = $Margin/VBox/Status

func _ready() -> void:
    side_label_node.text = side_label.to_upper()
    LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_BORDER, true)
    LungSaUIStyle.apply_kicker(side_label_node)
    LungSaUIStyle.apply_title(name_label, 21)
    LungSaUIStyle.apply_muted(stage_label, 12)
    LungSaUIStyle.apply_muted(trait_label, 12)
    LungSaUIStyle.apply_muted(hp_label, 12)
    LungSaUIStyle.apply_muted(status_label, 12)
    LungSaUIStyle.apply_hp_bar(hp_bar, 1.0)

func bind_creature(creature: BattleCreatureState) -> void:
    if creature == null:
        name_label.text = "No active creature"
        archetype_label.text = "—"
        stage_label.text = "Stage —"
        trait_label.text = "Trait —"
        hp_bar.max_value = 1.0
        hp_bar.value = 0.0
        hp_label.text = "— / —"
        status_label.text = "No battle state"
        LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_BORDER, true)
        LungSaUIStyle.apply_hp_bar(hp_bar, 0.0)
        return

    var accent: Color = LungSaUIStyle.get_archetype_color(creature.archetype)
    var hp_ratio: float = creature.get_hp_ratio()
    LungSaUIStyle.apply_battle_panel(self, accent, true)
    LungSaUIStyle.apply_hp_bar(hp_bar, hp_ratio)

    name_label.text = creature.display_name
    archetype_label.text = String(creature.archetype).to_upper()
    archetype_label.add_theme_color_override(&"font_color", accent.lightened(0.18))
    stage_label.text = String(creature.life_stage).capitalize()
    trait_label.text = _get_trait_name(creature.active_trait_id)
    hp_bar.max_value = float(maxi(creature.max_hp, 1))
    hp_bar.value = float(clampi(creature.current_hp, 0, maxi(creature.max_hp, 1)))
    hp_label.text = "%d / %d" % [creature.current_hp, creature.max_hp]
    status_label.text = _get_status_text(creature)

func _get_trait_name(trait_id: StringName) -> String:
    if trait_id == &"":
        return "No trait"
    var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
    return String(trait_id) if trait_definition == null else trait_definition.display_name

func _get_status_text(creature: BattleCreatureState) -> String:
    var parts: Array[String] = []
    if creature.guarding:
        parts.append("Guarding")
    if creature.power_modifier != 0:
        parts.append("Power %+d" % creature.power_modifier)
    if creature.priority_modifier != 0:
        parts.append("Priority %+d" % creature.priority_modifier)
    for status_id: StringName in creature.status_effect_ids:
        var status_definition: BattleStatusDefinition = ContentDB.get_definition(status_id) as BattleStatusDefinition
        parts.append(String(status_id) if status_definition == null else status_definition.display_name)
    if parts.is_empty():
        return "Ready"
    return "  •  ".join(parts)
