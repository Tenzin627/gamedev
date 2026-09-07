extends RegionLocalSystem
class_name FarmCreaturePresenterSystem

const FARM_CREATURE_PRESENTER_SCENE: PackedScene = preload("res://world/shared/farming/farm_creature_work_presenter.tscn")

@export var move_speed: float = 54.0
@export var idle_radius: float = 42.0
@export var shelter_anchor: Vector2 = Vector2(-64, 205)
@export var storage_anchor: Vector2 = Vector2(-480, 175)
@export var carry_seconds: float = 1.6

var _actors: Dictionary = {}
var _assignment: FarmAssignmentSystem = null
var _work_ai: FarmWorkAISystem = null
var _farm: FarmPlotSystem = null
var _container: Node2D = null
var _carry_until_by_creature: Dictionary = {}

func _ready() -> void:
    _container = Node2D.new()
    _container.name = "AssignedCreaturePresentation"
    add_child(_container)
    call_deferred("_bind_farm_systems")

func _bind_farm_systems() -> void:
    if region_root == null:
        return
    _assignment = region_root.get_local_system(&"FarmAssignmentSystem") as FarmAssignmentSystem
    _work_ai = region_root.get_local_system(&"FarmWorkAISystem") as FarmWorkAISystem
    _farm = region_root.get_local_system(&"FarmPlotSystem") as FarmPlotSystem
    if _assignment != null and not _assignment.assignments_changed.is_connected(_refresh_actors):
        _assignment.assignments_changed.connect(_refresh_actors)
    if _work_ai != null and not _work_ai.work_completed.is_connected(_on_work_completed):
        _work_ai.work_completed.connect(_on_work_completed)
    _refresh_actors()

func _process(delta: float) -> void:
    if _assignment == null or _farm == null:
        return
    var now_msec: int = Time.get_ticks_msec()
    for instance_id: String in _assignment.get_assigned_ids():
        var actor: FarmCreatureWorkPresenter = _actors.get(instance_id) as FarmCreatureWorkPresenter
        if actor == null:
            continue

        var carry_until: int = int(_carry_until_by_creature.get(instance_id, 0))
        if carry_until > now_msec:
            actor.set_work_state(storage_anchor, "Carrying to Chest", 1.0)
            actor.advance_presentation(delta, move_speed)
            continue
        if carry_until > 0:
            _carry_until_by_creature.erase(instance_id)

        var work: Dictionary = _work_ai.get_current_work(instance_id) if _work_ai != null else {}
        var target: Vector2 = _idle_position(instance_id)
        var state_text: String = "Resting"
        var progress: float = 0.0
        if not work.is_empty():
            if work.has("target_position"):
                target = work.get("target_position", target) as Vector2
            else:
                var cell: Vector2i = work.get("cell", Vector2i.ZERO) as Vector2i
                target = _farm.farm_cell_to_world_center(cell)
            var tag: String = str(work.get("tag", "work"))
            match tag:
                "water":
                    state_text = "Watering"
                "gather":
                    state_text = "Harvesting"
                "resource":
                    state_text = "Gathering Materials"
                "till":
                    state_text = "Tilling"
                "plant":
                    state_text = "Planting"
                _:
                    state_text = "Working"
            progress = _work_ai.get_progress(instance_id)
        actor.set_work_state(target, state_text, progress)
        actor.advance_presentation(delta, move_speed)

func _on_work_completed(instance_id: String, work_tag: StringName, _cell: Vector2i) -> void:
    if work_tag == &"gather" or work_tag == &"resource_output":
        _carry_until_by_creature[instance_id] = Time.get_ticks_msec() + int(carry_seconds * 1000.0)

func _refresh_actors() -> void:
    if _assignment == null:
        return
    var wanted: Array[String] = _assignment.get_assigned_ids()
    for key: Variant in _actors.keys():
        var id: String = str(key)
        if not wanted.has(id):
            var old_actor: Node = _actors.get(id) as Node
            if old_actor != null:
                old_actor.queue_free()
            _actors.erase(id)
            _carry_until_by_creature.erase(id)
    var model: CreatureCollectionModel = CreatureCollectionModel.new()
    for instance_id: String in wanted:
        if _actors.has(instance_id):
            continue
        var creature: CreatureInstanceData = model.get_creature(instance_id)
        if creature == null:
            continue
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
        if species == null:
            continue
        var actor: FarmCreatureWorkPresenter = FARM_CREATURE_PRESENTER_SCENE.instantiate() as FarmCreatureWorkPresenter
        if actor == null:
            continue
        actor.name = "FarmCreature_%s" % instance_id.replace(".", "_")
        actor.position = _idle_position(instance_id)
        _container.add_child(actor)
        actor.configure(instance_id, species.content_id, species.display_name, String(species.archetype))
        _actors[instance_id] = actor

func _idle_position(instance_id: String) -> Vector2:
    var index: int = 0
    if _assignment != null:
        index = maxi(_assignment.get_assigned_ids().find(instance_id), 0)
    var angle: float = float(index) * 1.0472
    return shelter_anchor + Vector2(cos(angle), sin(angle)) * idle_radius
