extends Sprite2D
class_name WorldStateVariantVisual2D

enum VisualKind { BRIDGE, ROUTE, WAYMARK }

@export_enum("Bridge", "Route", "Waymark") var visual_kind: int = VisualKind.BRIDGE
@export var active_variant: bool = false
@export var bridge_active_texture: Texture2D
@export var bridge_inactive_texture: Texture2D
@export var route_blocked_texture: Texture2D
@export var waymark_texture: Texture2D

func _ready() -> void:
    _refresh_visual()


func _refresh_visual() -> void:
    position = Vector2.ZERO
    modulate = Color.WHITE
    match visual_kind:
        VisualKind.BRIDGE:
            texture = bridge_active_texture if active_variant else bridge_inactive_texture
            position = Vector2(0, -2)
            scale = Vector2(0.4167, 0.3284)
        VisualKind.ROUTE:
            texture = null if active_variant else route_blocked_texture
            position = Vector2(0, -15)
            scale = Vector2(0.53125, 0.3546)
        VisualKind.WAYMARK:
            texture = waymark_texture
            position = Vector2(0, -32.5)
            scale = Vector2(0.1823, 0.2143)
            modulate = Color.WHITE if active_variant else Color("8b968b")
