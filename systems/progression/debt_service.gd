extends Node

signal debt_changed(current_due: int, remaining_total: int, total_paid: int)
signal installment_paid(amount: int, remaining_total: int)

const STATE_INITIALIZED: StringName = &"debt.initialized"
const STATE_REMAINING: StringName = &"debt.remaining_total"
const STATE_DUE: StringName = &"debt.current_due"
const STATE_TOTAL_PAID: StringName = &"debt.total_paid"
const STATE_GATE_TARGET: StringName = &"debt.payment_gate_target"
const STATE_GATE_PROGRESS: StringName = &"debt.payment_gate_progress"
const STATE_FIRST_PAYMENT_COMPLETE: StringName = &"debt.first_payment_complete"

func _ready() -> void:
    if not GameSession.session_started.is_connected(_on_session_started):
        GameSession.session_started.connect(_on_session_started)
    if not GameSession.session_imported.is_connected(_on_session_imported):
        GameSession.session_imported.connect(_on_session_imported)
    _emit_current_state_if_initialized()

func initialize_fresh_state(total_debt: int, gate_target: int, gate_progress: int = 0) -> void:
    var safe_total: int = maxi(total_debt, 0)
    var safe_target: int = maxi(gate_target, 0)
    var safe_progress: int = clampi(gate_progress, 0, safe_target)
    GameSession.set_value(STATE_INITIALIZED, true)
    GameSession.set_value(STATE_REMAINING, safe_total)
    GameSession.set_value(STATE_GATE_TARGET, safe_target)
    GameSession.set_value(STATE_GATE_PROGRESS, safe_progress)
    GameSession.set_value(STATE_DUE, maxi(safe_target - safe_progress, 0))
    GameSession.set_value(STATE_TOTAL_PAID, safe_progress)
    GameSession.set_value(STATE_FIRST_PAYMENT_COMPLETE, safe_target > 0 and safe_progress >= safe_target)
    debt_changed.emit(get_current_due(), get_remaining_total(), get_total_paid())

func initialize_if_needed() -> void:
    # Kept for compatibility with older callers. Fresh-state values now come only
    # from DemoBootstrap/GameProfileDefinition so loading an older save cannot
    # silently acquire a new canonical debt balance.
    _emit_current_state_if_initialized()

func get_current_due() -> int:
    return maxi(int(GameSession.get_value(STATE_DUE, 0)), 0)

func get_remaining_total() -> int:
    return maxi(int(GameSession.get_value(STATE_REMAINING, 0)), 0)

func get_total_paid() -> int:
    return maxi(int(GameSession.get_value(STATE_TOTAL_PAID, 0)), 0)

func get_payment_gate_target() -> int:
    return maxi(int(GameSession.get_value(STATE_GATE_TARGET, 0)), 0)

func get_payment_gate_progress() -> int:
    return clampi(int(GameSession.get_value(STATE_GATE_PROGRESS, 0)), 0, get_payment_gate_target())

func is_first_payment_complete() -> bool:
    return bool(GameSession.get_value(STATE_FIRST_PAYMENT_COMPLETE, false))

func apply_payment_credit(amount: int) -> int:
    if amount <= 0 or not bool(GameSession.get_value(STATE_INITIALIZED, false)):
        return 0
    var target: int = get_payment_gate_target()
    var old_progress: int = get_payment_gate_progress()
    var new_progress: int = clampi(old_progress + amount, 0, target)
    var applied: int = new_progress - old_progress
    GameSession.set_value(STATE_GATE_PROGRESS, new_progress)
    GameSession.set_value(STATE_TOTAL_PAID, new_progress)
    GameSession.set_value(STATE_DUE, maxi(target - new_progress, 0))
    GameSession.set_value(STATE_FIRST_PAYMENT_COMPLETE, target > 0 and new_progress >= target)
    debt_changed.emit(get_current_due(), get_remaining_total(), get_total_paid())
    return applied

func can_pay_current_due() -> bool:
    var due: int = get_current_due()
    return due > 0 and int(GameSession.get_value(&"currency", 0)) >= due

func pay_current_due() -> bool:
    if not can_pay_current_due():
        return false
    var due: int = get_current_due()
    var currency: int = int(GameSession.get_value(&"currency", 0))
    var remaining: int = maxi(get_remaining_total() - due, 0)
    var target: int = get_payment_gate_target()
    GameSession.set_value(&"currency", currency - due)
    GameSession.set_value(STATE_REMAINING, remaining)
    GameSession.set_value(STATE_GATE_PROGRESS, target)
    GameSession.set_value(STATE_DUE, 0)
    GameSession.set_value(STATE_TOTAL_PAID, target)
    GameSession.set_value(STATE_FIRST_PAYMENT_COMPLETE, true)
    WorldStateService.set_flag(&"world.central_basin.first_collection_paid", true)
    debt_changed.emit(0, remaining, target)
    installment_paid.emit(due, remaining)
    return true

func get_progress_text() -> String:
    return "PAYMENT GATE I  %d / %d  •  Marks %d" % [
        get_payment_gate_progress(),
        get_payment_gate_target(),
        int(GameSession.get_value(&"currency", 0)),
    ]

func _emit_current_state_if_initialized() -> void:
    if bool(GameSession.get_value(STATE_INITIALIZED, false)):
        debt_changed.emit(get_current_due(), get_remaining_total(), get_total_paid())

func _on_session_started(_profile_id: String) -> void:
    _emit_current_state_if_initialized()

func _on_session_imported() -> void:
    _emit_current_state_if_initialized()
