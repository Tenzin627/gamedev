extends Node2D
class_name FarmCrewBoard

@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    interactable.action_name = &"manage_farm_crew"
    interactable.prompt_text = "Manage farm crew"
    interactable.interaction_priority = 8
    interactable.interaction_requested.connect(_on_interaction_requested)

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return
    var panel: FarmAssignmentPanel = root.get_node_or_null(^"FarmAssignmentPanel") as FarmAssignmentPanel
    if panel != null:
        panel.open_panel()

func _draw() -> void:
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-32, -31), "FARM CREW", HORIZONTAL_ALIGNMENT_CENTER, 64, 10, Color(0.96, 0.9, 0.68, 1.0))
