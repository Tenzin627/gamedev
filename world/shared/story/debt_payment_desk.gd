extends Node2D
class_name DebtPaymentDesk

const CONFIRM_CONTEXT: StringName = &"phase7_pay_debt"
const MAIN_QUEST_ID: StringName = &"quest.central_basin.receipt_that_bites_back"

@export var prompt_text: String = "Settle Ledger collection"
@onready var interactable: InteractableComponent = $Interactable
var _hud: CoreHUD = null

func _ready() -> void:
    interactable.action_name = InteractionActions.INTERACT
    interactable.prompt_text = prompt_text
    interactable.interaction_priority = 8
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
    if _hud == null:
        _resolve_hud()
    if DebtService.is_first_payment_complete():
        _show("COLLECTION 01 is stamped PAID. Unfortunately the scroll continues.")
        return
    if QuestService.get_quest_status(MAIN_QUEST_ID) != QuestService.STATUS_COMPLETED:
        _show("Ledger clearance pending. Finish Tavi's paperwork emergency first.")
        return
    var due: int = DebtService.get_current_due()
    var currency: int = int(GameSession.get_value(&"currency", 0))
    if currency < due:
        _show("NO PARTIALS. Wallet %d. Collection %d. Short %d." % [currency, due, due - currency])
        return
    if _hud != null:
        _hud.show_confirmation(
            "STAMP COLLECTION 01?",
            "Hand over %d coins.\n\nCurrent debt: %d\nBalance after stamp: %d\n\nThis closes the collection, not the terrible decision." % [due, DebtService.get_remaining_total(), DebtService.get_remaining_total() - due],
            CONFIRM_CONTEXT,
            "STAMP  •  PAY %d" % due,
            "Keep My Money"
        )

func _on_confirmation_resolved(context_id: StringName, accepted: bool) -> void:
    if context_id != CONFIRM_CONTEXT or not accepted:
        return
    if not DebtService.pay_current_due():
        _show("Payment failed. The Ledger remains emotionally unaffected.")

func _show(message: String, seconds: float = 2.8) -> void:
    if _hud == null:
        _resolve_hud()
    if _hud != null:
        _hud.show_status_message(message, seconds)
