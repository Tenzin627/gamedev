extends Node2D
class_name VillageWagerTable

const QUEST_ID: StringName = &"quest.central_basin.lucky_bowl"
const PLAYED_KEY: StringName = &"demo_wager_played"
const WON_KEY: StringName = &"demo_wager_won"
const CONFIRM_CONTEXT: StringName = &"phase7_lucky_bowl"
const STAKE: int = 20
const WIN_PAYOUT: int = 80
const RESEARCH_STIPEND: int = 10
const WIN_CHANCE: float = 0.55

@onready var interactable: InteractableComponent = $Interactable
var _hud: CoreHUD = null

func _ready() -> void:
    interactable.action_name = InteractionActions.INTERACT
    interactable.prompt_text = "Try the Lucky Bowl"
    interactable.interaction_priority = 6
    interactable.interaction_requested.connect(_on_interaction_requested)
    call_deferred("_resolve_hud")

func _exit_tree() -> void:
    if _hud != null and is_instance_valid(_hud) and _hud.confirmation_resolved.is_connected(_on_confirmation_resolved):
        _hud.confirmation_resolved.disconnect(_on_confirmation_resolved)

func _resolve_hud() -> void:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    _hud = root.get_node_or_null(^"CoreHUD") as CoreHUD if root != null else null
    if _hud != null and not _hud.confirmation_resolved.is_connected(_on_confirmation_resolved):
        _hud.confirmation_resolved.connect(_on_confirmation_resolved)

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    if int(GameSession.get_value(PLAYED_KEY, 0)) > 0:
        var won: bool = bool(GameSession.get_value(WON_KEY, false))
        _show("The bowl already judged you. Result: %s. One throw means one throw." % ("LUCKY" if won else "UNLUCKY"))
        return
    if QuestService.get_quest_status(QUEST_ID) != QuestService.STATUS_ACTIVE:
        _show("Pao is taking exactly one very transparent bet. Talk to him first.")
        return
    var currency: int = int(GameSession.get_value(&"currency", 0))
    if currency < STAKE:
        _show("The bowl requires %d coins. Apparently destiny has overhead." % STAKE)
        return
    if _hud == null:
        _resolve_hud()
    if _hud != null:
        _hud.show_confirmation(
            "MAKE THE WAGER?",
            "ODDS 55%%  •  ONE THROW\nStake %d coins. Bowl payout on a win: %d.\nPao pays a %d-coin research stipend either way." % [STAKE, WIN_PAYOUT, RESEARCH_STIPEND],
            CONFIRM_CONTEXT,
            "Tempt Fate  •  -%d" % STAKE,
            "Keep My Coins"
        )

func _on_confirmation_resolved(context_id: StringName, accepted: bool) -> void:
    if context_id != CONFIRM_CONTEXT or not accepted:
        return
    var currency: int = int(GameSession.get_value(&"currency", 0))
    if currency < STAKE or int(GameSession.get_value(PLAYED_KEY, 0)) > 0:
        return
    GameSession.set_value(&"currency", currency - STAKE)
    var won: bool = randf() < WIN_CHANCE
    if won:
        GameSession.set_value(&"currency", int(GameSession.get_value(&"currency", 0)) + WIN_PAYOUT)
    GameSession.set_value(WON_KEY, won)
    GameSession.set_value(PLAYED_KEY, 1)
    QuestService.evaluate_all_active()
    var wallet: int = int(GameSession.get_value(&"currency", 0))
    if _hud == null:
        _resolve_hud()
    if _hud == null:
        return
    if won:
        _hud.show_fortune_reveal(
            "LUCKY BOWL  •  ONE THROW",
            "FORTUNE FAVORS YOU",
            "+70 NET",
            "Stake -20  •  Bowl +80  •  Pao +10\nWallet now %d. Pao has already rewritten the experiment notes." % wallet,
            "win",
            "LUCKY"
        )
    else:
        _hud.show_fortune_reveal(
            "LUCKY BOWL  •  ONE THROW",
            "THE BOWL KEEPS ITS CUT",
            "-10 NET",
            "Stake -20  •  Pao +10\nWallet now %d. The odds were honest. The bowl was not kind." % wallet,
            "loss",
            "UNLUCKY"
        )

func _show(message: String, seconds: float = 2.8) -> void:
    if _hud == null:
        _resolve_hud()
    if _hud != null:
        _hud.show_status_message(message, seconds)
