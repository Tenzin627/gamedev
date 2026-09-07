extends Resource
class_name HabitatSpawnEntry

@export_category("Creature")
## Stable creature.* ID for the species that can spawn from this entry.
@export var species_id: StringName = &""

@export_category("Spawn Amount")
## Relative chance for this species compared with the other entries in this habitat. Example: weights 3 and 1 are roughly 75% / 25%.
@export_range(0.01, 1000.0, 0.01) var spawn_weight: float = 1.0
## Smallest group this species can appear in during one refill.
@export_range(1, 8, 1) var min_group_size: int = 1
## Largest group this species can appear in during one refill. The habitat population cap always wins.
@export_range(1, 8, 1) var max_group_size: int = 1

@export_category("Conditions")
## Leave empty for any time. Otherwise use time tags such as dawn, day, dusk, or night.
@export var active_time_tags: Array[StringName] = []
## Habitat ecology health required before this species can spawn.
@export_range(0.0, 1.0, 0.01) var minimum_ecology_health: float = 0.0

func validate_entry() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if species_id == &"":
        errors.append("Habitat spawn entry is missing species_id")
    elif not String(species_id).begins_with("creature."):
        errors.append("Habitat species_id should use creature.* stable ID: %s" % String(species_id))
    elif not ContentDB.get_definition(species_id) is CreatureSpeciesDefinition:
        errors.append("Habitat species_id does not resolve to a creature: %s" % String(species_id))
    if spawn_weight <= 0.0:
        errors.append("Habitat spawn entry %s must have positive spawn_weight" % String(species_id))
    if min_group_size < 1:
        errors.append("Habitat spawn entry %s min_group_size must be at least 1" % String(species_id))
    if max_group_size < min_group_size:
        errors.append("Habitat spawn entry %s max_group_size must be >= min_group_size" % String(species_id))
    return errors
