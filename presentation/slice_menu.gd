extends CanvasLayer
## A small game shell: title, pause, settings, a real save/continue flow.
var _hud: CoreHUD
var _screen: Control
var _title: Label
var _body: Label
var _buttons: VBoxContainer
var _onboarding: bool = false
var _was_running: bool = true
var _guide: PanelContainer
var _guide_label: Label

func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS
    _hud = get_parent() as CoreHUD
    var music: AudioStreamPlayer = AudioStreamPlayer.new()
    var theme_stream: AudioStreamWAV = (load("res://art/audio/basin_theme.wav") as AudioStreamWAV).duplicate()
    theme_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    theme_stream.loop_end = 352800
    music.stream = theme_stream
    music.bus = "Music"
    music.volume_db = -20
    add_child(music)
    music.play()
    _screen = Control.new()
    _screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_screen)
    var shade: ColorRect = ColorRect.new()
    shade.color = Color("101f19ec")
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _screen.add_child(shade)
    var center: CenterContainer = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _screen.add_child(center)
    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = Vector2(720,540)
    LungSaUIStyle.apply_modal_panel(panel, LungSaUIStyle.COLOR_ACCENT)
    center.add_child(panel)
    var margin: MarginContainer = MarginContainer.new()
    for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
    panel.add_child(margin)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",28)
    margin.add_child(row)
    var art: TextureRect = TextureRect.new()
    art.texture = load("res://art/characters/player/farmer_s.png") as Texture2D
    art.custom_minimum_size = Vector2(210,280)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(art)
    var col: VBoxContainer = VBoxContainer.new()
    col.custom_minimum_size.x = 390
    col.add_theme_constant_override("separation",14)
    row.add_child(col)
    var kicker: Label = Label.new()
    kicker.text = "THE LEDGER  /  15-MINUTE DEMO  /  COLLECTION 01"
    LungSaUIStyle.apply_kicker(kicker)
    col.add_child(kicker)
    _title = Label.new()
    LungSaUIStyle.apply_title(_title,48)
    col.add_child(_title)
    _body = Label.new()
    _body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.custom_minimum_size = Vector2(390,90)
    LungSaUIStyle.apply_muted(_body,15)
    col.add_child(_body)
    _buttons = VBoxContainer.new()
    _buttons.add_theme_constant_override("separation",8)
    col.add_child(_buttons)
    _screen.hide()
    _build_guide()
    if not bool(GameSession.get_value(&"slice.welcomed",false)):
        call_deferred("_open",true)

func _build_guide() -> void:
    _guide = PanelContainer.new()
    _guide.position = Vector2(20,198)
    _guide.custom_minimum_size = Vector2(250,140)
    _guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
    LungSaUIStyle.apply_panel(_guide)
    _guide_label = Label.new()
    LungSaUIStyle.apply_muted(_guide_label, 13)
    _guide.add_child(_guide_label)
    _hud.root.add_child(_guide)
    _hud.root.move_child(_guide,0)

func _process(_delta: float) -> void:
    if _guide == null: return
    var has_farm: bool = get_tree().get_first_node_in_group(&"region_root").get_node_or_null("Systems/FarmPlotSystem") != null if get_tree().get_first_node_in_group(&"region_root") != null else false
    _guide.visible = has_farm and not _screen.visible and not _hud.is_blocking_gameplay()
    var lines: String = "YOUR FIRST HARVEST\n"
    var actions: Array[String] = ["till","plant","water","harvest"]
    var labels: Array[String] = ["[1] Hoe  •  [F] Till a plot","[5] Seeds  •  [F] Plant","[2] Water  •  [F] Water daily","Rest 3 watered nights • Harvest"]
    for i: int in range(actions.size()):
        var done: bool = bool(GameSession.get_value(StringName("farm_tutorial."+actions[i]),false))
        lines += ("✓ " if done else "○ ")+labels[i]+"\n"
    _guide_label.text = lines.trim_suffix("\n")

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if _screen.visible:
            _close()
            get_viewport().set_input_as_handled()
        elif not _hud.is_blocking_gameplay():
            _open(false)
            get_viewport().set_input_as_handled()

func _open(welcome: bool = false) -> void:
    _onboarding = welcome
    _was_running = WorldTimeService.running
    _screen.show()
    _hud.set_external_modal_blocked(&"slice_menu",true)
    get_tree().paused = true
    _title.text = "Lung Sa" if welcome else "Field Paused"
    _title.add_theme_font_size_override("font_size",48 if welcome else 36)
    _body.text = "You won a farm. You also inherited its 100,000-coin Ledger debt.\nEarn, explore, Bond creatures, solve one ridiculous village problem, and make the first 500-coin payment.\n\nWASD Move   E Talk   F Farm   J Journal   Esc Pause" if welcome else "First Collection session.\nSave progress, adjust sound, or return to the demo."
    _rebuild_buttons()

func _rebuild_buttons() -> void:
    for child: Node in _buttons.get_children():
        _buttons.remove_child(child)
        child.queue_free()
    var first: Button = _button("Enter the demo" if _onboarding else "Return to the demo", _close, true)
    if not _onboarding: _button("Save progress",_save)
    if SaveService.has_slot(0): _button("Continue saved session",_load_save)
    var sound: HSlider = HSlider.new()
    sound.min_value = -40
    sound.max_value = 0
    sound.step = 1
    sound.value = float(SettingsService.get_value(&"audio",&"master_db",-6.0))
    sound.tooltip_text = "Master volume"
    sound.value_changed.connect(func(value: float) -> void: SettingsService.set_value(&"audio",&"master_db",value))
    var label: Label = Label.new()
    label.text = "MASTER VOLUME"
    LungSaUIStyle.apply_kicker(label)
    _buttons.add_child(label)
    _buttons.add_child(sound)
    if not _onboarding: _button("Start a new session…",_confirm_restart)
    _button("Quit game",_quit_game)
    first.grab_focus()

func _button(text_value: String, action: Callable, primary: bool = false) -> Button:
    var button: Button = Button.new()
    button.text = text_value
    button.custom_minimum_size.y = 40
    LungSaUIStyle.apply_button(button,primary)
    button.pressed.connect(action)
    _buttons.add_child(button)
    return button

func _close() -> void:
    GameSession.set_value(&"slice.welcomed",true)
    _screen.hide()
    get_tree().paused = false
    _hud.set_external_modal_blocked(&"slice_menu",false)
    WorldTimeService.set_running(_was_running)

func _save() -> void:
    var error: Error = SaveService.save_slot(0)
    _body.text = "Session saved. Your farm, creatures, quests, and Ledger state are safe." if error == OK else "Save failed. Please try again."

func _load_save() -> void:
    var error: Error = SaveService.load_slot(0)
    if error != OK:
        _body.text = "Could not read this save. Your current journey is unchanged."
        return
    get_tree().paused = false
    _screen.hide()
    SceneRouter.restore_saved_location()

func _confirm_restart() -> void:
    _body.text = "Start over? Unsaved progress will be lost. Your saved session remains available through Continue."
    for child: Node in _buttons.get_children():
        _buttons.remove_child(child)
        child.queue_free()
    _button("Keep this session",_rebuild_buttons,true).grab_focus()
    _button("Start over",func() -> void:
        _close()
        DemoBootstrap.restart_demo()
    )

func _exit_tree() -> void:
    for child: Node in get_children():
        if child is AudioStreamPlayer: child.stop()

func _quit_game() -> void:
    for child: Node in get_children():
        if child is AudioStreamPlayer: child.stop()
    await get_tree().create_timer(0.2,true).timeout
    get_tree().quit()
