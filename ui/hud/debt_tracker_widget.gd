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
    var due: int = DebtService.get_current_due()
    var remaining: int = DebtService.get_remaining_total()
    var currency: int = int(GameSession.get_value(&"currency", 0))
    kicker.text = "THE LEDGER  •  COLLECTION 01"
    funds_bar.max_value = float(DebtService.FIRST_INSTALLMENT)
    if DebtService.is_first_payment_complete():
        stamp.text = "PAID"
        stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_SUCCESS)
        amount.text = "500 / 500  STAMPED"
        funds_bar.value = float(DebtService.FIRST_INSTALLMENT)
        _style_bar(LungSaUIStyle.COLOR_SUCCESS)
        meta.text = "Outstanding balance  %d" % remaining
        return

    var ready_funds: int = mini(currency, DebtService.FIRST_INSTALLMENT)
    var shortfall: int = maxi(due - currency, 0)
    funds_bar.value = float(ready_funds)
    if shortfall <= 0:
        stamp.text = "READY"
        stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_SUCCESS)
        amount.text = "%d DUE  •  FUNDS READY" % due
        meta.text = "Wallet %d  •  Return to the Ledger desk" % currency
        _style_bar(LungSaUIStyle.COLOR_SUCCESS)
    else:
        stamp.text = "OPEN"
        stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_LEDGER)
        amount.text = "%d DUE" % due
        meta.text = "Wallet %d  •  Short %d" % [currency, shortfall]
        _style_bar(LungSaUIStyle.COLOR_LEDGER)

func _style_bar(accent: Color) -> void:
    funds_bar.add_theme_stylebox_override(&"background", LungSaUIStyle.panel_style(Color("#08120FDD"), Color("#33443B"), 1, 4, 0.0))
    funds_bar.add_theme_stylebox_override(&"fill", LungSaUIStyle.panel_style(accent.darkened(0.08), accent, 0, 4, 0.0))

func _on_debt_changed(_due: int, _remaining: int, _paid: int) -> void:
    refresh()

func _on_session_state_changed(key: StringName, _value: Variant) -> void:
    if key == &"currency" or String(key).begins_with("debt."):
        refresh()
