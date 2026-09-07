#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

project = text("project.godot")
style = text("ui/shared/lung_sa_ui_style.gd")
theme = text("ui/shared/lung_sa_theme.tres")
dialogue_scene = text("ui/dialogue/dialogue_panel.tscn")
dialogue_script = text("ui/dialogue/dialogue_panel.gd")
coordinator = text("systems/dialogue/dialogue_coordinator.gd")
npc_definition = text("data/npcs/npc_definition.gd")

assert '0.90.0-phase8-ui-dialogue-polish' in project
assert 'theme/custom="res://ui/shared/lung_sa_theme.tres"' in project
assert 'PANEL_RADIUS: int = 14' in style
assert 'BUTTON_RADIUS: int = 10' in style
assert 'BUTTON_HEIGHT: float = 44.0' in style
assert 'apply_modal_panel' in style
assert 'apply_character_frame' in style
assert 'apply_choice_button' in style
assert 'PanelContainer/styles/panel' in theme
assert 'Button/styles/normal' in theme

for token in ('PortraitFrame', 'Portrait', 'Role', 'SpeechPanel', 'ConversationKicker'):
    assert token in dialogue_scene
assert 'mouse_filter = 0' in dialogue_scene
assert 'apply_character_frame' in dialogue_script
assert 'apply_choice_button' in dialogue_script
assert 'portrait: Texture2D = null' in dialogue_script
assert 'role: String = "Resident"' in dialogue_script
assert 'npc_definition.portrait_texture' in coordinator
assert 'npc_definition.world_texture' in coordinator
assert '@export var portrait_texture: Texture2D' in npc_definition

# All interactive UI scripts should share the central style helper. Backdrop and
# transition overlays are presentation canvases rather than interactive panels.
exceptions = {
    ROOT / 'ui' / 'battle' / 'battle_backdrop.gd',
    ROOT / 'ui' / 'transitions' / 'scene_transition_overlay.gd',
}
for path in sorted((ROOT / 'ui').rglob('*.gd')):
    source = path.read_text(encoding='utf-8')
    first = source.splitlines()[0] if source else ''
    if path in exceptions or 'func _ready' not in source:
        continue
    if 'extends PanelContainer' in first or 'extends Control' in first:
        assert 'LungSaUIStyle' in source, f'{path.relative_to(ROOT)} does not use LungSaUIStyle'

# One-off static font colors are retired from interactive UI scenes; semantic
# colors are applied by the shared style helper at runtime.
for path in sorted((ROOT / 'ui').rglob('*.tscn')):
    if path.name == 'scene_transition_overlay.tscn':
        continue
    source = path.read_text(encoding='utf-8')
    assert 'theme_override_colors/font_color = Color' not in source, f'one-off font color remains in {path.relative_to(ROOT)}'

print('PHASE 8 UI + DIALOGUE: PASS | global theme + unified panels/buttons + character portrait dialogue')
