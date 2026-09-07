extends Node2D
class_name FarmStorageChest

@onready var interactable: InteractableComponent = $Interactable

func _ready() -> void:
    interactable.prompt_text = "Open farm storage"
    interactable.interaction_requested.connect(_on_interaction_requested)

func _on_interaction_requested(_action: StringName, interactor: Node) -> void:
    var region: RegionRoot = _find_region_root()
    if region == null:
        return
    var storage: FarmStorageSystem = region.get_local_system(&"FarmStorageSystem") as FarmStorageSystem
    var panel: FarmStoragePanel = region.get_node_or_null(^"FarmStoragePanel") as FarmStoragePanel
    var player: PlayerActor = interactor as PlayerActor
    if player == null:
        player = region.get_node_or_null(^"PlayerActor") as PlayerActor
    if storage != null and panel != null and player != null:
        panel.open_panel(storage, player)

func _find_region_root() -> RegionRoot:
    var node: Node = self
    while node != null:
        if node is RegionRoot:
            return node as RegionRoot
        node = node.get_parent()
    return null

