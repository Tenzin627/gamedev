extends Node

func _ready() -> void:
    var failures: Array[String] = []

    var side_quest: QuestDefinition = ContentDB.get_definition(&"quest.central_basin.lucky_bowl") as QuestDefinition
    _expect(side_quest != null, "Lucky Bowl quest missing", failures)
    if side_quest != null:
        _expect(side_quest.reward_currency == 10, "Lucky Bowl stipend must be 10 coins", failures)

    var fortune_scene: PackedScene = load("res://ui/shared/fortune_reveal_panel.tscn") as PackedScene
    _expect(fortune_scene != null, "Fortune reveal scene missing", failures)
    if fortune_scene != null:
        var fortune_panel: Node = fortune_scene.instantiate()
        _expect(fortune_panel is FortuneRevealPanel, "Fortune reveal scene does not instantiate FortuneRevealPanel", failures)
        fortune_panel.queue_free()

    var debt_scene: PackedScene = load("res://ui/hud/debt_tracker_widget.tscn") as PackedScene
    _expect(debt_scene != null, "Debt tracker scene missing", failures)
    var bond_scene: PackedScene = load("res://ui/creatures/bond_encounter_panel.tscn") as PackedScene
    _expect(bond_scene != null, "Bond wager panel scene missing", failures)

    _expect(DebtService.INITIAL_TOTAL_DEBT == 100000, "Ledger total debt changed", failures)
    _expect(DebtService.FIRST_INSTALLMENT == 500, "First collection changed", failures)

    if failures.is_empty():
        print("PHASE 7 GAMBLING IDENTITY REGRESSION: PASS")
    else:
        for failure: String in failures:
            push_error("PHASE 7 GAMBLING IDENTITY: %s" % failure)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
