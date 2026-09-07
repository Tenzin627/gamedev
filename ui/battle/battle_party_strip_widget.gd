extends PanelContainer
class_name BattlePartyStripWidget

@onready var title_label: Label = $Margin/HBox/Title
@onready var slots_row: HBoxContainer = $Margin/HBox/Slots

func _ready() -> void:
    LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_BORDER, false)
    LungSaUIStyle.apply_kicker(title_label)

func bind_team(team: BattleTeamState) -> void:
    for child: Node in slots_row.get_children():
        slots_row.remove_child(child)
        child.queue_free()

    if team == null:
        title_label.text = "PARTY"
        return

    title_label.text = team.display_name.to_upper()
    for index: int in range(BattleTeamState.MAX_TEAM_SIZE):
        slots_row.add_child(_build_slot(team, index))

func _build_slot(team: BattleTeamState, index: int) -> Control:
    var slot_panel: PanelContainer = PanelContainer.new()
    slot_panel.custom_minimum_size = Vector2(102.0, 48.0)

    if index >= team.creatures.size():
        slot_panel.add_theme_stylebox_override(&"panel", LungSaUIStyle.panel_style(Color("#111D18B8"), LungSaUIStyle.COLOR_BORDER_SOFT, 1, LungSaUIStyle.BUTTON_RADIUS))
        var empty_label: Label = Label.new()
        empty_label.text = "—"
        empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        empty_label.modulate = LungSaUIStyle.COLOR_MUTED
        slot_panel.add_child(empty_label)
        return slot_panel

    var creature: BattleCreatureState = team.creatures[index]
    if creature == null:
        return slot_panel

    var accent: Color = LungSaUIStyle.get_archetype_color(creature.archetype)
    var is_active: bool = index == team.active_index
    var border_width: int = 2 if is_active else 1
    var fill: Color = Color("#20352bf2") if is_active else Color("#14231dda")
    slot_panel.add_theme_stylebox_override(&"panel", LungSaUIStyle.panel_style(fill, accent, border_width, LungSaUIStyle.BUTTON_RADIUS))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override(&"margin_left", 7)
    margin.add_theme_constant_override(&"margin_top", 5)
    margin.add_theme_constant_override(&"margin_right", 7)
    margin.add_theme_constant_override(&"margin_bottom", 5)
    slot_panel.add_child(margin)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override(&"separation", 3)
    margin.add_child(box)

    var name_row: HBoxContainer = HBoxContainer.new()
    box.add_child(name_row)

    var marker: Label = Label.new()
    marker.custom_minimum_size = Vector2(12.0, 0.0)
    marker.text = "●" if is_active else ""
    marker.add_theme_color_override(&"font_color", accent)
    name_row.add_child(marker)

    var name_label: Label = Label.new()
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.add_theme_font_size_override(&"font_size", 11)
    name_label.text = creature.display_name
    name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    if creature.is_fainted():
        name_label.modulate = Color("#7d8981")
    name_row.add_child(name_label)

    var hp_bar: ProgressBar = ProgressBar.new()
    hp_bar.custom_minimum_size = Vector2(0.0, 7.0)
    hp_bar.max_value = float(maxi(creature.max_hp, 1))
    hp_bar.value = float(clampi(creature.current_hp, 0, maxi(creature.max_hp, 1)))
    hp_bar.show_percentage = false
    LungSaUIStyle.apply_compact_hp_bar(hp_bar, creature.get_hp_ratio())
    box.add_child(hp_bar)

    return slot_panel
