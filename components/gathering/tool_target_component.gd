extends Area2D
class_name ToolTargetComponent

signal tool_applied(tool: ToolDefinition, inventory: InventoryComponent, source: Node)
signal enabled_changed(is_enabled: bool)

@export var accepted_tool_tags: PackedStringArray = PackedStringArray()
@export var tool_target_priority: int = 0
@export_range(0, 10, 1) var minimum_tool_tier: int = 0
@export var enabled: bool = true:
    set(value):
        if enabled == value:
            return
        enabled = value
        if is_inside_tree():
            monitorable = enabled
        enabled_changed.emit(enabled)
@export var target_point_path: NodePath

func _ready() -> void:
    monitorable = enabled

func accepts_tool(tool: ToolDefinition) -> bool:
    if not enabled or tool == null:
        return false
    if tool.tool_tier < minimum_tool_tier:
        return false
    if accepted_tool_tags.is_empty():
        return true
    return accepted_tool_tags.has(String(tool.tool_tag))

func get_tool_target_priority() -> int:
    return tool_target_priority

func get_tool_target_position() -> Vector2:
    if not target_point_path.is_empty():
        var point: Node = get_node_or_null(target_point_path)
        if point is Node2D:
            return (point as Node2D).global_position
    return global_position

func apply_tool(tool: ToolDefinition, inventory: InventoryComponent, source: Node) -> bool:
    if not accepts_tool(tool) or inventory == null or source == null:
        return false
    tool_applied.emit(tool, inventory, source)
    return true
