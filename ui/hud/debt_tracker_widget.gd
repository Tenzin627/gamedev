extends PanelContainer
class_name DebtTrackerWidget

@onready var kicker: Label = $Margin/VBox/Header/Kicker
@onready var stamp: Label = $Margin/VBox/Header/Stamp
@onready var amount: Label = $Margin/VBox/Amount
@onready var funds_bar: ProgressBar = $Margin/VBox/FundsBar
@onready var meta: Label = $Margin/VBox/Meta

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, false)
    LungSaUIStyle.apply_kicker(kicker)
    LungSaUIStyle.apply_title(amount, 18)
    LungSaUIStyle.apply_muted(meta, 11)
    stamp.add_theme_font_size_override(&"font_size", 11)
    stamp.add_theme_color_override(&"font_outline_color", Color("#08120FFF"))
    stamp.add_theme_constant_override(&"outline_size", 4)
    if not DebtService.debt_changed.is_connected(_on_debt_changed):
        DebtService.debt_changed.connect(_on_debt_changed)
    if not GameSession.session_state_changed.is_connected(_on_session_state_changed):
        GameSession.session_state_changed.connect(_on_session_state_changed)
    refresh()

func _exit_tree() -> void:
    if DebtService.debt_changed.is_connected(_on_debt_changed):
        DebtService.debt_changed.disconnect(_on_debt_changed)
    if GameSession.session_state_changed.is_connected(_on_session_state_changed):
        GameSession.session_state_changed.disconnect(_on_session_state_changed)

func refresh() -> void:
    var target: int = maxi(DebtService.get_payment_gate_target(), 0)
    var progress: int = DebtService.get_payment_gate_progress()
    var remaining_debt: int = DebtService.get_remaining_total()
    var currency: int = int(GameSession.get_value(&"currency", 0))
    var remaining_gate: int = maxi(target - progress, 0)

    kicker.text = "THE LEDGER  •  PAYMENT GATE I"
    funds_bar.max_value = float(maxi(target, 1))
    funds_bar.value = float(progress)

    if DebtService.is_first_payment_complete():
        stamp.text = "GATE MET"
        stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_SUCCESS)
        amount.text = "%s / %s Marks" % [_format_number(progress), _format_number(target)]
        meta.text = "Outstanding debt  %s Marks" % _format_number(remaining_debt)
        _style_bar(LungSaUIStyle.COLOR_SUCCESS)
        return

    stamp.text = "OPEN"
    stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_LEDGER)
    amount.text = "%s / %s Marks" % [_format_number(progress), _format_number(target)]
    meta.text = "Outstanding debt  %s  •  Wallet %s  •  Gate remaining %s" % [
        _format_number(remaining_debt),
        _format_number(currency),
        _format_number(remaining_gate),
    ]
    _style_bar(LungSaUIStyle.COLOR_LEDGER)

func _format_number(value: int) -> String:
    var negative: bool = value < 0
    var digits: String = str(absi(value))
    var formatted: String = ""
    while digits.length() > 3:
        formatted = "," + digits.substr(digits.length() - 3, 3) + formatted
        digits = digits.substr(0, digits.length() - 3)
    formatted = digits + formatted
    return "-" + formatted if negative else formatted

func _style_bar(accent: Color) -> void:
    funds_bar.add_theme_stylebox_override(&"background", LungSaUIStyle.panel_style(Color("#08120FDD"), Color("#33443B"), 1, 4, 0.0))
    funds_bar.add_theme_stylebox_override(&"fill", LungSaUIStyle.panel_style(accent.darkened(0.08), accent, 0, 4, 0.0))

func _on_debt_changed(_due: int, _remaining: int, _paid: int) -> void:
    refresh()

func _on_session_state_changed(key: StringName, _value: Variant) -> void:
    if key == &"currency" or String(key).begins_with("debt."):
        refresh()
