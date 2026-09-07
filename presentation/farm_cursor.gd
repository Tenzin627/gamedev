extends Node2D

var _player: PlayerActor
var _farm: FarmPlotSystem
var _label: Label
var _panel: PanelContainer
var _pulse: float = 0.0
var _feedback: String = ""
var _feedback_time: float = 0.0
var _sound: AudioStreamPlayer

func _ready() -> void:
    _player = get_parent() as PlayerActor
    z_index = 5
    _sound = AudioStreamPlayer.new()
    _sound.stream = load("res://art/audio/farm_action.wav") as AudioStreamWAV
    _sound.volume_db = -12
    _sound.bus = "SFX"
    add_child(_sound)
    call_deferred("_bind")

func _bind() -> void:
    var region: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if region == null:
        return
    _farm = region.get_local_system(&"FarmPlotSystem") as FarmPlotSystem
    if _farm == null:
        return
    var hud: CoreHUD = region.get_node_or_null("CoreHUD") as CoreHUD
    if hud == null:
        return
    _panel = PanelContainer.new()
    _panel.position = Vector2(20, 400)
    _panel.custom_minimum_size = Vector2(266, 94)
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    LungSaUIStyle.apply_panel(_panel, true)
    _label = Label.new()
    _label.add_theme_font_size_override("font_size", 14)
    _label.add_theme_color_override("font_color", LungSaUIStyle.COLOR_INK)
    _panel.add_child(_label)
    hud.root.add_child(_panel)
    hud.root.move_child(_panel, 0)
    _player.farm_interaction_component.farm_action_performed.connect(_on_action)
    _player.farm_interaction_component.farm_action_failed.connect(_on_failure)

func _process(delta: float) -> void:
    _pulse += delta
    _feedback_time = maxf(0.0, _feedback_time - delta)
    queue_redraw()
    if _panel == null or _farm == null:
        return
    var cell: Vector2i = _player.farm_interaction_component.get_target_cell(_farm)
    _panel.visible = _player.input_enabled and _farm.is_cell_in_farm(cell)
    if not _panel.visible:
        return
    var plot: Dictionary = _farm.get_plot(cell)
    var status: String = "UNTILLED  •  Hoe [1]"
    var tip: String = "[F] Prepare soil"
    if bool(plot.get("tilled", false)):
        status = "WET SOIL" if bool(plot.get("watered", false)) else "DRY SOIL"
        tip = "Select Moonroot [5] or Sunpod [6] → [F] Plant"
    var crop_id: StringName = StringName(str(plot.get("crop_id", "")))
    if crop_id != &"":
        var crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
        var crop_name: String = crop.display_name.to_upper() if crop != null else "CROP"
        var max_stage: int = maxi((crop.growth_stages - 1) if crop != null else 1, 1)
        status = "%s  •  Growth %d / %d" % [crop_name, int(plot.get("stage", 0)), max_stage]
        tip = "Watered • Rest once to advance" if bool(plot.get("watered", false)) else "Needs water • [2] then [F]"
    if bool(plot.get("ready", false)):
        var ready_crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
        status = "%s  •  READY" % (ready_crop.display_name.to_upper() if ready_crop != null else "CROP")
        tip = "[F] Harvest • goes to Pack"
    _label.text = "HOMESTEAD  /  PLOT %02d
%s
%s" % [cell.y * 8 + cell.x + 1, status, _feedback if _feedback_time > 0 else tip]

func _draw() -> void:
    if _farm == null or not _player.input_enabled:
        return
    var cell: Vector2i = _player.farm_interaction_component.get_target_cell(_farm)
    if not _farm.is_cell_in_farm(cell):
        return
    var point: Vector2 = to_local(_farm.farm_cell_to_world_center(cell)) - Vector2(30, 30)
    var color: Color = Color("efd78c")
    color.a = 0.72 + sin(_pulse * 4.0) * 0.18
    draw_style_box(LungSaUIStyle.panel_style(Color(1, 0.9, 0.5, 0.06), color, 2, 6, 0), Rect2(point, Vector2(60, 60)))

func _on_action(action: StringName, cell: Vector2i) -> void:
    var words: Dictionary = {
        &"till": "Soil prepared",
        &"water": "Watered for tomorrow",
        &"plant": _planted_feedback(cell),
        &"harvest": "Harvest added to Pack",
    }
    _feedback = words.get(action, "Done")
    _feedback_time = 1.5
    _sound.pitch_scale = 1.3 if action == &"harvest" else 1.0
    _sound.play()
    GameSession.set_value(StringName("farm_tutorial." + String(action)), true)

func _planted_feedback(cell: Vector2i) -> String:
    if _farm == null:
        return "Seed planted"
    var crop_id: StringName = StringName(str(_farm.get_plot(cell).get("crop_id", "")))
    var crop: CropDefinition = ContentDB.get_definition(crop_id) as CropDefinition
    return "%s planted" % crop.display_name if crop != null else "Seed planted"

func _on_failure(reason: StringName) -> void:
    var words: Dictionary = {
        &"inventory_full": "Pack full • Sell or store something",
        &"cannot_till": "Already tilled • plant or water next",
        &"cannot_water": "Till first, or soil is already wet",
        &"cannot_plant": "Needs empty, tilled soil",
        &"empty_hotbar_slot": "Choose Hoe [1], Water [2], or Seed [5/6]",
        &"nothing_to_do": "Choose a farm tool or seed",
    }
    _feedback = words.get(reason, "Choose a farm tool")
    _feedback_time = 2.0

func _exit_tree() -> void:
    if _sound != null:
        _sound.stop()
