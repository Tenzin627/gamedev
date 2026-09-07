extends Node

func _ready() -> void:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://world/central_basin/zones/demo_farm.tscn") as PackedScene
    _expect(scene != null, "Demo Farm scene missing", failures)
    if scene != null:
        var farm: RegionRoot = scene.instantiate() as RegionRoot
        add_child(farm)
        await get_tree().process_frame
        await get_tree().process_frame
        var assignment: FarmAssignmentSystem = farm.get_local_system(&"FarmAssignmentSystem") as FarmAssignmentSystem
        var work_ai: FarmWorkAISystem = farm.get_local_system(&"FarmWorkAISystem") as FarmWorkAISystem
        var storage: FarmStorageSystem = farm.get_local_system(&"FarmStorageSystem") as FarmStorageSystem
        var tile_content: TileWorldContentSystem = farm.get_local_system(&"TileWorldContentSystem") as TileWorldContentSystem
        _expect(assignment != null, "Farm assignment system missing", failures)
        _expect(work_ai != null, "Farm work AI system missing", failures)
        _expect(storage != null and storage.storage != null, "Farm storage system missing", failures)
        _expect(tile_content != null, "Tile content system missing", failures)
        if assignment != null:
            _expect(assignment.max_assigned_creatures == 3, "Phase 5 farm crew cap must be 3", failures)
        if work_ai != null:
            _expect(is_equal_approx(work_ai.helper_yield_multiplier, 0.4), "Helper yield multiplier must be 0.4", failures)
        if tile_content != null:
            _expect(not tile_content.get_helper_gather_jobs().is_empty(), "Home Farm needs at least one material gathering job", failures)
        farm.queue_free()

    var bramble: CreatureSpeciesDefinition = ContentDB.get_definition(&"creature.brambleback.baby") as CreatureSpeciesDefinition
    _expect(bramble != null, "Brambleback species missing", failures)
    if bramble != null:
        _expect(bramble.farm_work_profile_id == &"farm_work.brambleback", "Brambleback must use its Phase 5 work profile", failures)
        var profile: FarmWorkProfileDefinition = ContentDB.get_definition(bramble.farm_work_profile_id) as FarmWorkProfileDefinition
        _expect(profile != null, "Brambleback work profile missing", failures)
        if profile != null:
            var has_gather: bool = false
            for rule: FarmWorkRule in profile.get_enabled_rules():
                if rule.kind == FarmWorkRule.Kind.GATHER_RESOURCE:
                    has_gather = true
            _expect(has_gather, "Brambleback profile must include material gathering", failures)

    if failures.is_empty():
        print("PHASE 5 FARM AUTOMATION REGRESSION: PASS")
    else:
        for failure: String in failures:
            push_error("PHASE 5 FARM AUTOMATION: %s" % failure)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
