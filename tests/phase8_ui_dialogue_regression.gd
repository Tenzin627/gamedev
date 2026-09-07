extends Node

func _ready() -> void:
    var failures: Array[String] = []

    var dialogue_scene: PackedScene = load("res://ui/dialogue/dialogue_panel.tscn") as PackedScene
    _expect(dialogue_scene != null, "Dialogue scene missing", failures)
    if dialogue_scene != null:
        var panel: DialoguePanel = dialogue_scene.instantiate() as DialoguePanel
        _expect(panel != null, "Dialogue scene does not instantiate DialoguePanel", failures)
        if panel != null:
            add_child(panel)
            var mei: NPCDefinition = ContentDB.get_definition(&"npc.central_basin.mei") as NPCDefinition
            _expect(mei != null, "Mei NPC definition missing", failures)
            var portrait: Texture2D = null
            if mei != null:
                portrait = mei.portrait_texture if mei.portrait_texture != null else mei.world_texture
            panel.open_dialogue("Mei", "Portrait dialogue regression check.", [], portrait, "Local Guide")
            _expect(panel.visible, "Dialogue panel did not open", failures)
            _expect(panel.get_node_or_null(^"BottomMargin/DialogueRow/PortraitColumn/PortraitFrame") != null, "Portrait frame missing", failures)
            _expect(panel.get_node_or_null(^"BottomMargin/DialogueRow/SpeechPanel") != null, "Speech panel missing", failures)
            var role: Label = panel.get_node_or_null(^"BottomMargin/DialogueRow/PortraitColumn/Role") as Label
            _expect(role != null and role.text == "LOCAL GUIDE", "NPC role did not bind to portrait card", failures)
            panel.close_dialogue()
            _expect(not panel.visible, "Dialogue panel did not close", failures)
            panel.queue_free()

    if failures.is_empty():
        print("PHASE 8 UI + DIALOGUE REGRESSION: PASS")
    else:
        for failure: String in failures:
            push_error("PHASE 8 UI + DIALOGUE: %s" % failure)

    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
