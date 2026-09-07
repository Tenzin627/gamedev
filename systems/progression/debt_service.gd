extends Node

signal debt_changed(current_due: int, remaining_total: int, total_paid: int)
signal installment_paid(amount: int, remaining_total: int)

const INITIAL_TOTAL_DEBT: int = 100000
const FIRST_INSTALLMENT: int = 500
const STATE_INITIALIZED: StringName = &"debt.initialized"
const STATE_REMAINING: StringName = &"debt.remaining_total"
const STATE_DUE: StringName = &"debt.current_due"
const STATE_TOTAL_PAID: StringName = &"debt.total_paid"
const STATE_FIRST_PAYMENT_COMPLETE: StringName = &"debt.first_payment_complete"

func _ready() -> void:
    if not GameSession.session_started.is_connected(_on_session_started):
        GameSession.session_started.connect(_on_session_started)
    if not GameSession.session_imported.is_connected(_on_session_imported):
        GameSession.session_imported.connect(_on_session_imported)
    initialize_if_needed()

func initialize_if_needed() -> void:
    if bool(GameSession.get_value(STATE_INITIALIZED, false)):
        debt_changed.emit(get_current_due(), get_remaining_total(), get_total_paid())
        return
    GameSession.set_value(STATE_INITIALIZED, true)
    GameSession.set_value(STATE_REMAINING, INITIAL_TOTAL_DEBT)
    GameSession.set_value(STATE_DUE, FIRST_INSTALLMENT)
    GameSession.set_value(STATE_TOTAL_PAID, 0)
    GameSession.set_value(STATE_FIRST_PAYMENT_COMPLETE, 0)
    debt_changed.emit(FIRST_INSTALLMENT, INITIAL_TOTAL_DEBT, 0)

func get_current_due() -> int:
    return maxi(int(GameSession.get_value(STATE_DUE, FIRST_INSTALLMENT)), 0)

func get_remaining_total() -> int:
    return maxi(int(GameSession.get_value(STATE_REMAINING, INITIAL_TOTAL_DEBT)), 0)

func get_total_paid() -> int:
    return maxi(int(GameSession.get_value(STATE_TOTAL_PAID, 0)), 0)

func is_first_payment_complete() -> bool:
    return bool(GameSession.get_value(STATE_FIRST_PAYMENT_COMPLETE, 0))

func can_pay_current_due() -> bool:
    var due: int = get_current_due()
    return due > 0 and int(GameSession.get_value(&"currency", 0)) >= due

func pay_current_due() -> bool:
    if not can_pay_current_due():
        return false
    var due: int = get_current_due()
    var currency: int = int(GameSession.get_value(&"currency", 0))
    var remaining: int = maxi(get_remaining_total() - due, 0)
    var total_paid: int = get_total_paid() + due
    GameSession.set_value(&"currency", currency - due)
    GameSession.set_value(STATE_REMAINING, remaining)
    GameSession.set_value(STATE_DUE, 0)
    GameSession.set_value(STATE_TOTAL_PAID, total_paid)
    GameSession.set_value(STATE_FIRST_PAYMENT_COMPLETE, 1)
    WorldStateService.set_flag(&"world.central_basin.first_collection_paid", true)
    debt_changed.emit(0, remaining, total_paid)
    installment_paid.emit(due, remaining)
    return true

func get_progress_text() -> String:
    if is_first_payment_complete():
        return "FIRST COLLECTION PAID  •  Remaining %d" % get_remaining_total()
    return "DEBT DUE  %d  •  Coins %d" % [get_current_due(), int(GameSession.get_value(&"currency", 0))]

func _on_session_started(_profile_id: String) -> void:
    initialize_if_needed()

func _on_session_imported() -> void:
    initialize_if_needed()
