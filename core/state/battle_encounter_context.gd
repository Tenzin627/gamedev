extends RefCounted
class_name BattleEncounterContext

var encounter_id: String = ""
var encounter_kind: StringName = &"wild"
var source_region_id: StringName = &""
var source_zone_id: StringName = &""
var source_scene_path: String = ""
var source_spawn_token: String = ""
var source_habitat_instance_id: StringName = &""
var opponent_species_ids: Array[StringName] = []
var environment_id: StringName = &""

func is_valid() -> bool:
    return not encounter_id.is_empty() and not source_scene_path.is_empty() and not opponent_species_ids.is_empty()

func to_dict() -> Dictionary:
    var opponent_ids: Array[String] = []
    for species_id: StringName in opponent_species_ids:
        opponent_ids.append(String(species_id))
    return {
        "encounter_id": encounter_id,
        "encounter_kind": String(encounter_kind),
        "source_region_id": String(source_region_id),
        "source_zone_id": String(source_zone_id),
        "source_scene_path": source_scene_path,
        "source_spawn_token": source_spawn_token,
        "source_habitat_instance_id": String(source_habitat_instance_id),
        "opponent_species_ids": opponent_ids,
        "environment_id": String(environment_id),
    }

static func from_dict(data: Dictionary) -> BattleEncounterContext:
    var result: BattleEncounterContext = BattleEncounterContext.new()
    result.encounter_id = str(data.get("encounter_id", ""))
    result.encounter_kind = StringName(str(data.get("encounter_kind", "wild")))
    result.source_region_id = StringName(str(data.get("source_region_id", "")))
    result.source_zone_id = StringName(str(data.get("source_zone_id", "")))
    result.source_scene_path = str(data.get("source_scene_path", ""))
    result.source_spawn_token = str(data.get("source_spawn_token", ""))
    result.source_habitat_instance_id = StringName(str(data.get("source_habitat_instance_id", "")))
    result.environment_id = StringName(str(data.get("environment_id", "")))
    var opponents_variant: Variant = data.get("opponent_species_ids", [])
    if opponents_variant is Array:
        for value: Variant in Array(opponents_variant):
            var species_id: StringName = StringName(str(value))
            if species_id != &"":
                result.opponent_species_ids.append(species_id)
    return result
