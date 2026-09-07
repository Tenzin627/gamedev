extends PanelContainer
class_name BondEncounterPanel

signal standard_attempt_requested
signal paid_retry_requested
signal close_requested
signal panel_state_changed(is_open: bool)

@onready var kicker_label: Label = $Margin/VBox/Kicker
@onready var title_label: Label = $Margin/VBox/Title
@onready var chance_bar: ProgressBar = $Margin/VBox/ChanceBar
@onready var info_label: Label = $Margin/VBox/Info
@onready var result_label: Label = $Margin/VBox/Result
@onready var attempt_button: Button = $Margin/VBox/Buttons/AttemptButton
@onready var retry_button: Button = $Margin/VBox/Buttons/RetryButton
@onready var close_button: Button = $Margin/VBox/Buttons/CloseButton

func _ready() -> void:
    add_to_group(&"bond_encounter_ui")
    LungSaUIStyle.apply_battle_panel(self, LungSaUIStyle.COLOR_ACCENT, true)
    LungSaUIStyle.apply_kicker(kicker_label)
    LungSaUIStyle.apply_title(title_label, 26)
    LungSaUIStyle.apply_muted(info_label, 12)
    LungSaUIStyle.apply_battle_button(attempt_button, LungSaUIStyle.COLOR_SUCCESS, true)
    LungSaUIStyle.apply_battle_button(retry_button, LungSaUIStyle.COLOR_LEDGER, true)
    LungSaUIStyle.apply_battle_button(close_button, LungSaUIStyle.COLOR_BORDER, false)
    attempt_button.pressed.connect(_on_attempt_pressed)
    retry_button.pressed.connect(_on_retry_pressed)
    close_button.pressed.connect(_on_close_pressed)
    visible = false

func open_encounter(display_name: String, chance: float, currency: int, retry_cost: int, max_paid_retries: int = 1) -> void:
    var chance_percent: int = int(round(chance * 100.0))
    kicker_label.text = "BOND WAGER  •  ONE FREE THROW"
    title_label.text = display_name
    chance_bar.max_value = 100.0
    chance_bar.value = float(chance_percent)
    _style_chance_bar(chance)
    info_label.text = "CHANCE %d%%  •  WALLET %d\nFree attempt now  •  Tempt Fate once for %d coins" % [chance_percent, currency, retry_cost]
    if max_paid_retries <= 0:
        info_label.text = "CHANCE %d%%  •  WALLET %d\nOne free attempt. No paid retries for this encounter." % [chance_percent, currency]
    result_label.text = "The creature watches. Weaken it first, or trust terrible instincts."
    result_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_INK)
    attempt_button.text = "CAST BOND  •  FREE"
    attempt_button.visible = true
    attempt_button.disabled = false
    retry_button.visible = false
    close_button.text = "Walk Away"
    visible = true
    panel_state_changed.emit(true)
    attempt_button.grab_focus()

func show_failed(currency: int, retry_cost: int, retry_available: bool = true) -> void:
    attempt_button.visible = false
    retry_button.visible = retry_available
    retry_button.disabled = not retry_available or currency < retry_cost
    retry_button.text = "TEMPT FATE  •  -%d COINS" % retry_cost
    kicker_label.text = "THE FIRST THROW FAILED"
    if retry_available:
        if currency >= retry_cost:
            result_label.text = "Fate offers exactly one bad financial decision. Pay %d coins for one final Bond attempt." % retry_cost
            result_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_LEDGER)
        else:
            result_label.text = "Fate wants %d coins. Your wallet contains %d. Walking away is suddenly very responsible." % [retry_cost, currency]
            result_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_DANGER)
    else:
        result_label.text = "FATE SPENT. No Bond attempts remain in this encounter."
        result_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_FAINT)
    close_button.text = "Walk Away"
    if not retry_button.disabled:
        retry_button.grab_focus()
    else:
        close_button.grab_focus()

func show_success(creature_name: String, joined_party: bool) -> void:
    kicker_label.text = "FORTUNE SETTLED  •  BONDED"
    result_label.text = "%s accepted the Bond.%s" % [creature_name, " Joined your active party." if joined_party else " Added to your creature roster."]
    result_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_SUCCESS)
    attempt_button.visible = false
    retry_button.visible = false
    close_button.text = "Collect Your Luck"
    close_button.grab_focus()

func show_message(message: String) -> void:
    result_label.text = message

func request_close() -> void:
    close_requested.emit()
    close_panel()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func _style_chance_bar(chance: float) -> void:
    var accent: Color = LungSaUIStyle.COLOR_DANGER
    if chance >= 0.66:
        accent = LungSaUIStyle.COLOR_SUCCESS
    elif chance >= 0.40:
        accent = LungSaUIStyle.COLOR_ACCENT
    chance_bar.add_theme_stylebox_override(&"background", LungSaUIStyle.panel_style(Color("#08120FDD"), Color("#33443B"), 1, 5, 0.0))
    chance_bar.add_theme_stylebox_override(&"fill", LungSaUIStyle.panel_style(accent.darkened(0.08), accent, 0, 5, 0.0))

func _on_attempt_pressed() -> void:
    standard_attempt_requested.emit()

func _on_retry_pressed() -> void:
    paid_retry_requested.emit()

func _on_close_pressed() -> void:
    request_close()
