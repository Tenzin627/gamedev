extends Node2D
class_name DiscoveryLandmark

@export var discovery_id: StringName = &""
@export var prompt_text: String = "Inspect landmark"
@export var radius: float = 26.0
@export var visual_label: String = "LANDMARK"

var _interactable: InteractableComponent = null
var _service: ExplorationProgressService = null
var _definition: DiscoveryDefinition = null

func _ready() -> void:
    _service = ExplorationProgressService.new()
    add_child(_service)
    _definition = ContentDB.get_definition(discovery_id) as DiscoveryDefinition
    _interactable = get_node_or_null(^"Interactable") as InteractableComponent
    if _interactable != null:
        _interactable.interaction_requested.connect(_on_interaction)
    _refresh_prompt()


func _on_interaction(_action: StringName, _interactor: Node) -> void:
    if _service == null:
        return
    var was_new: bool = _service.discover(discovery_id)
    _refresh_prompt()
    if _definition == null:
        return
    if was_new:
        _show_status("Region Note found: %s. View findings with [K]." % _definition.display_name, 3.0)
    else:
        _show_status("%s — %s" % [_definition.display_name, _definition.description], 3.5)

func _refresh_prompt() -> void:
    if _interactable == null:
        return
    if _service != null and _service.is_discovered(discovery_id) and _definition != null:
        _interactable.prompt_text = "Review %s" % _definition.display_name
    else:
        _interactable.prompt_text = prompt_text

func _show_status(message: String, seconds: float) -> void:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if root == null:
        return
    var hud: CoreHUD = root.get_node_or_null(^"CoreHUD") as CoreHUD
    if hud != null:
        hud.show_status_message(message, seconds)
