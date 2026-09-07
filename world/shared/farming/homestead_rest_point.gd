extends Node2D
class_name HomesteadRestPoint

@export var prompt_text: String = "Rest until morning"
@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    interactable.prompt_text = prompt_text
    interactable.interaction_requested.connect(_on_interaction_requested)

func _on_interaction_requested(_action: StringName, _interactor: Node) -> void:
    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    var restored: int = collection.restore_all_health()
    var total_minutes: int = WorldTimeService.get_total_game_minutes()
    var current_day_index: int = int(floor(float(total_minutes) / float(WorldTimeService.MINUTES_PER_DAY)))
    var next_morning: int = (current_day_index + 1) * WorldTimeService.MINUTES_PER_DAY + 360
    WorldTimeService.set_total_game_minutes(next_morning)
    var hud: CoreHUD = _find_hud()
    if hud != null:
        var heal_text: String = "Creatures recovered." if restored > 0 else "Creatures are already rested."
        hud.show_status_message("New morning. Watered crops advanced one day. %s" % heal_text, 3.2)

func _find_hud() -> CoreHUD:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return null
    return root.get_node_or_null(^"CoreHUD") as CoreHUD

