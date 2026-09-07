extends RefCounted
class_name LungSaUIStyle

# Phase 8 UI contract. Every screen uses the same ink/parchment/jade family,
# corner language, border weights, spacing rhythm, and button states.
const COLOR_INK: Color = Color("#F4F0E4")
const COLOR_MUTED: Color = Color("#B3B9AE")
const COLOR_FAINT: Color = Color("#778278")
const COLOR_ACCENT: Color = Color("#E6C86F")
const COLOR_ACCENT_SOFT: Color = Color("#BFA765")
const COLOR_PANEL: Color = Color("#10221DEE")
const COLOR_PANEL_DEEP: Color = Color("#091612F7")
const COLOR_PANEL_LIGHT: Color = Color("#1A3028F7")
const COLOR_PANEL_SOFT: Color = Color("#263D33EE")
const COLOR_BORDER: Color = Color("#587064")
const COLOR_BORDER_SOFT: Color = Color("#354D42")
const COLOR_FOCUS: Color = Color("#F2D98D")
const COLOR_DANGER: Color = Color("#C96F63")
const COLOR_SUCCESS: Color = Color("#84B978")
const COLOR_LEDGER: Color = Color("#D27662")
const COLOR_ATTACK: Color = Color("#CF795F")
const COLOR_SPEED: Color = Color("#67AEB2")
const COLOR_GUARD: Color = Color("#83A96E")
const COLOR_HEAL: Color = Color("#8FBD84")
const COLOR_STATUS: Color = Color("#B594C3")
const COLOR_UTILITY: Color = Color("#B5A276")

const PANEL_RADIUS: int = 14
const SUBPANEL_RADIUS: int = 11
const BUTTON_RADIUS: int = 10
const PANEL_PADDING: float = 10.0
const BUTTON_HEIGHT: float = 44.0

static func panel_style(fill: Color = COLOR_PANEL, border: Color = COLOR_BORDER, border_width: int = 1, radius: int = PANEL_RADIUS, padding: float = PANEL_PADDING) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(border_width)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.01, 0.02, 0.016, 0.36)
    style.shadow_size = 9
    style.shadow_offset = Vector2(0, 4)
    style.content_margin_left = padding
    style.content_margin_right = padding
    style.content_margin_top = padding
    style.content_margin_bottom = padding
    return style

static func apply_panel(panel: PanelContainer, elevated: bool = false) -> void:
    var fill: Color = COLOR_PANEL_LIGHT if elevated else COLOR_PANEL
    var border: Color = COLOR_ACCENT_SOFT.darkened(0.24) if elevated else COLOR_BORDER_SOFT
    panel.add_theme_stylebox_override(&"panel", panel_style(fill, border, 2 if elevated else 1, PANEL_RADIUS, PANEL_PADDING))

static func apply_modal_panel(panel: PanelContainer, accent: Color = COLOR_ACCENT) -> void:
    panel.add_theme_stylebox_override(&"panel", panel_style(COLOR_PANEL_DEEP, accent.darkened(0.18), 2, PANEL_RADIUS + 2, 12.0))

static func apply_subpanel(panel: PanelContainer, accent: Color = COLOR_BORDER_SOFT) -> void:
    panel.add_theme_stylebox_override(&"panel", panel_style(Color("#142A23E6"), accent, 1, SUBPANEL_RADIUS, 8.0))

static func apply_character_frame(panel: PanelContainer, accent: Color = COLOR_ACCENT) -> void:
    panel.add_theme_stylebox_override(&"panel", panel_style(Color("#0C1C17F8"), accent.darkened(0.16), 3, 18, 8.0))

static func apply_toast(panel: PanelContainer) -> void:
    panel.add_theme_stylebox_override(&"panel", panel_style(Color("#172B24F8"), COLOR_ACCENT_SOFT.darkened(0.12), 1, SUBPANEL_RADIUS, 8.0))

static func apply_button(button: Button, emphasized: bool = false) -> void:
    button.focus_mode = Control.FOCUS_ALL
    button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_HEIGHT)
    button.add_theme_font_size_override(&"font_size", 15)
    var normal_fill: Color = Color("#395244F7") if emphasized else Color("#21372EF3")
    button.add_theme_stylebox_override(&"normal", panel_style(normal_fill, COLOR_BORDER_SOFT, 1, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"hover", panel_style(Color("#345044FC"), COLOR_ACCENT_SOFT, 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"pressed", panel_style(Color("#456251FF"), COLOR_ACCENT, 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"focus", panel_style(Color("#30483CFC"), COLOR_FOCUS, 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"disabled", panel_style(Color("#18271FC4"), Color("#33443B"), 1, BUTTON_RADIUS, 8.0))
    button.add_theme_color_override(&"font_color", COLOR_INK)
    button.add_theme_color_override(&"font_hover_color", Color.WHITE)
    button.add_theme_color_override(&"font_focus_color", Color.WHITE)
    button.add_theme_color_override(&"font_disabled_color", COLOR_FAINT)

static func apply_choice_button(button: Button, index: int = 0) -> void:
    apply_button(button, index == 0)
    button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 250.0), maxf(button.custom_minimum_size.y, 48.0))
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT

static func apply_tab_button(button: Button, active: bool) -> void:
    apply_button(button, active)
    if active:
        button.add_theme_color_override(&"font_color", COLOR_ACCENT)

static func apply_title(label: Label, size: int = 26) -> void:
    label.add_theme_font_size_override(&"font_size", size)
    label.add_theme_color_override(&"font_color", COLOR_INK)

static func apply_section_title(label: Label, size: int = 18) -> void:
    label.add_theme_font_size_override(&"font_size", size)
    label.add_theme_color_override(&"font_color", COLOR_ACCENT_SOFT)

static func apply_kicker(label: Label) -> void:
    label.add_theme_font_size_override(&"font_size", 11)
    label.add_theme_color_override(&"font_color", COLOR_ACCENT)

static func apply_muted(label: Label, size: int = 12) -> void:
    label.add_theme_font_size_override(&"font_size", size)
    label.add_theme_color_override(&"font_color", COLOR_MUTED)

static func apply_body(label: RichTextLabel, size: int = 16) -> void:
    label.add_theme_color_override(&"default_color", COLOR_INK)
    label.add_theme_font_size_override(&"normal_font_size", size)
    label.add_theme_color_override(&"font_selected_color", COLOR_PANEL_DEEP)
    label.add_theme_color_override(&"selection_color", COLOR_ACCENT)

static func apply_battle_panel(panel: PanelContainer, accent: Color = COLOR_BORDER, elevated: bool = true) -> void:
    var fill: Color = COLOR_PANEL_DEEP if elevated else COLOR_PANEL
    panel.add_theme_stylebox_override(&"panel", panel_style(fill, accent.darkened(0.24), 2, PANEL_RADIUS, 9.0))

static func apply_battle_button(button: Button, accent: Color = COLOR_ACCENT, emphasized: bool = false) -> void:
    button.focus_mode = Control.FOCUS_ALL
    button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_HEIGHT)
    button.add_theme_font_size_override(&"font_size", 15)
    var normal_fill: Color = Color("#31493DF8") if emphasized else Color("#192F27F5")
    button.add_theme_stylebox_override(&"normal", panel_style(normal_fill, accent.darkened(0.34), 1, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"hover", panel_style(Color("#304B3DFC"), accent, 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"pressed", panel_style(Color("#3E5949FF"), accent.lightened(0.08), 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"focus", panel_style(Color("#2B463AFC"), accent.lightened(0.12), 2, BUTTON_RADIUS, 8.0))
    button.add_theme_stylebox_override(&"disabled", panel_style(Color("#14231DC4"), Color("#3D4E45"), 1, BUTTON_RADIUS, 8.0))
    button.add_theme_color_override(&"font_color", COLOR_INK)
    button.add_theme_color_override(&"font_hover_color", Color.WHITE)
    button.add_theme_color_override(&"font_focus_color", Color.WHITE)
    button.add_theme_color_override(&"font_disabled_color", COLOR_FAINT)

static func apply_battle_choice_button(button: Button, accent: Color = COLOR_ACCENT) -> void:
    apply_battle_button(button, accent, false)
    button.custom_minimum_size = Vector2(246.0, 78.0)
    button.add_theme_font_size_override(&"font_size", 15)

static func apply_hp_bar(bar: ProgressBar, ratio: float = 1.0) -> void:
    var fill_color: Color = get_health_color(ratio)
    bar.add_theme_stylebox_override(&"background", panel_style(Color("#08120FDD"), Color("#33443B"), 1, 5, 0.0))
    bar.add_theme_stylebox_override(&"fill", panel_style(fill_color, fill_color.lightened(0.15), 0, 5, 0.0))

static func apply_compact_hp_bar(bar: ProgressBar, ratio: float = 1.0) -> void:
    var fill_color: Color = get_health_color(ratio)
    bar.add_theme_stylebox_override(&"background", panel_style(Color("#08120FDD"), Color("#2F3B34"), 0, 3, 0.0))
    bar.add_theme_stylebox_override(&"fill", panel_style(fill_color, fill_color, 0, 3, 0.0))

static func get_health_color(ratio: float) -> Color:
    if ratio <= 0.25:
        return Color("#C85F57")
    if ratio <= 0.50:
        return Color("#D6A95F")
    return Color("#74A96D")

static func get_archetype_color(archetype_value: StringName) -> Color:
    if archetype_value == &"attack":
        return COLOR_ATTACK
    if archetype_value == &"speed":
        return COLOR_SPEED
    if archetype_value == &"guard":
        return COLOR_GUARD
    return COLOR_ACCENT

static func get_role_color(role_value: String) -> Color:
    var normalized: String = role_value.to_lower()
    if normalized == "damage":
        return COLOR_ATTACK
    if normalized == "defense":
        return COLOR_GUARD
    if normalized == "recovery":
        return COLOR_HEAL
    if normalized == "status" or normalized == "debuff" or normalized == "control":
        return COLOR_STATUS
    if normalized == "buff":
        return COLOR_SPEED
    return COLOR_UTILITY
