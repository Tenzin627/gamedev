extends PanelContainer
class_name QuestJournalPanel

signal panel_state_changed(is_open: bool)

@onready var _list: VBoxContainer = $Margin/Content/Split/QuestScroll/QuestList
@onready var _detail_title: Label = $Margin/Content/Split/DetailMargin/Detail/DetailTitle
@onready var _detail_body: RichTextLabel = $Margin/Content/Split/DetailMargin/Detail/DetailBody
@onready var _active_button: Button = $Margin/Content/Tabs/ActiveButton
@onready var _completed_button: Button = $Margin/Content/Tabs/CompletedButton
@onready var _close_button: Button = $Margin/Content/Header/CloseButton
var _show_completed: bool = false
var _quest_buttons: Array[Button] = []

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title($Margin/Content/Header/Title, 28)
    LungSaUIStyle.apply_title(_detail_title, 21)
    LungSaUIStyle.apply_body(_detail_body, 15)
    LungSaUIStyle.apply_button(_close_button, false)
    _close_button.pressed.connect(close_panel)
    _active_button.pressed.connect(_show_active)
    _completed_button.pressed.connect(_show_completed_tab)
    if not QuestService.quest_accepted.is_connected(_on_quest_changed):
        QuestService.quest_accepted.connect(_on_quest_changed)
    if not QuestService.quest_updated.is_connected(_on_quest_changed):
        QuestService.quest_updated.connect(_on_quest_changed)
    if not QuestService.quest_completed.is_connected(_on_quest_changed):
        QuestService.quest_completed.connect(_on_quest_changed)
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed(&"ui_cancel"):
        close_panel()
        _mark_input_handled()

func open_panel() -> void:
    _show_completed = false
    visible = true
    _refresh()
    panel_state_changed.emit(true)

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func toggle_panel() -> void:
    if visible:
        close_panel()
    else:
        open_panel()

func _refresh() -> void:
    for child: Node in _list.get_children():
        child.queue_free()
    _quest_buttons.clear()
    var ids: Array[StringName] = QuestService.get_completed_quest_ids() if _show_completed else QuestService.get_active_quest_ids()
    ids.sort_custom(_sort_quest_ids)
    if ids.is_empty():
        var empty: Label = Label.new()
        empty.text = "No completed quests." if _show_completed else "No active quest yet."
        _list.add_child(empty)
        _detail_title.text = "Journal"
        _detail_body.text = "Completed quests remain here for review." if _show_completed else "No active quest. Talk to Basin residents or check the Ledger for available work."
        _refresh_tab_styles()
        return
    for quest_id: StringName in ids:
        var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
        var button: Button = Button.new()
        button.text = definition.display_name if definition != null else String(quest_id)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.focus_mode = Control.FOCUS_ALL
        LungSaUIStyle.apply_button(button, false)
        button.pressed.connect(_select_quest.bind(quest_id))
        _list.add_child(button)
        _quest_buttons.append(button)
    _select_quest(ids[0])
    _quest_buttons[0].grab_focus()
    _refresh_tab_styles()

func _select_quest(quest_id: StringName) -> void:
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    if definition == null:
        return
    _detail_title.text = definition.display_name
    var lines: PackedStringArray = []
    lines.append(definition.description)
    lines.append("")
    lines.append("[b]Objectives[/b]")
    for resource: Resource in definition.objectives:
        var objective: QuestObjectiveDefinition = resource as QuestObjectiveDefinition
        if objective == null:
            continue
        var current: int = QuestService.get_objective_progress(quest_id, objective.objective_id)
        var required: int = maxi(objective.required_amount, 1)
        var marker: String = "✓" if current >= required else "•"
        lines.append("%s %s  [%d/%d]" % [marker, objective.description, mini(current, required), required])
    if definition.reward_currency != 0:
        lines.append("")
        lines.append("[b]Reward[/b]  %d currency" % definition.reward_currency)
    if QuestService.get_quest_status(quest_id) == QuestService.STATUS_COMPLETED:
        lines.append("")
        lines.append("[b]Completed[/b]")
    _detail_body.text = "\n".join(lines)

func _show_active() -> void:
    _show_completed = false
    _refresh()
    _refresh_tab_styles()

func _show_completed_tab() -> void:
    _show_completed = true
    _refresh()
    _refresh_tab_styles()

func _on_quest_changed(_quest_id: StringName) -> void:
    if visible:
        _refresh()

func _sort_quest_ids(a: StringName, b: StringName) -> bool:
    var da: QuestDefinition = ContentDB.get_definition(a) as QuestDefinition
    var db: QuestDefinition = ContentDB.get_definition(b) as QuestDefinition
    var an: String = da.display_name if da != null else String(a)
    var bn: String = db.display_name if db != null else String(b)
    return an.naturalnocasecmp_to(bn) < 0

func _refresh_tab_styles() -> void:
    if _active_button != null:
        LungSaUIStyle.apply_tab_button(_active_button, not _show_completed)
    if _completed_button != null:
        LungSaUIStyle.apply_tab_button(_completed_button, _show_completed)

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
