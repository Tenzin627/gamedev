extends ContentDefinition
class_name HabitatDefinition

@export_category("Habitat Identity")
## Ecology tags this habitat provides. Creature species use these to determine whether they belong here.
@export var habitat_tags: Array[StringName] = []
## Optional region tags required before this habitat can spawn creatures.
@export var required_region_tags: Array[StringName] = []
## Optional zone tags required before this habitat can spawn creatures.
@export var required_zone_tags: Array[StringName] = []

@export_category("Creature Population")
## Maximum number of wild creatures this habitat tries to keep alive at once. Ecology health can lower the effective cap.
@export_range(1, 24, 1) var max_creatures_alive: int = 4
## Number of wild creatures the habitat tries to establish when the zone first loads. Clamped to Max Creatures Alive.
@export_range(0, 24, 1) var initial_creatures: int = 2
## Delay after a successful spawn group before this habitat can refill again.
@export_range(0.25, 120.0, 0.25, "suffix:s") var respawn_delay_seconds: float = 8.0

@export_category("Species")
## Creatures that can appear here. Each entry controls species chance and group size.
@export var spawn_entries: Array[HabitatSpawnEntry] = []

@export_category("Spawn Safety")
## Creatures will not spawn closer than this distance to the player.
@export_range(0.0, 1024.0, 1.0, "suffix:px") var minimum_player_distance: float = 150.0
## Minimum spacing between newly spawned wild creatures and existing wild creatures.
@export_range(0.0, 256.0, 1.0, "suffix:px") var creature_spacing: float = 34.0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if habitat_tags.is_empty():
        errors.append("Habitat %s should define at least one habitat tag" % String(content_id))
    if spawn_entries.is_empty():
        errors.append("Habitat %s has no spawn entries" % String(content_id))
    for entry_resource: Resource in spawn_entries:
        if not entry_resource is HabitatSpawnEntry:
            errors.append("Habitat %s has a non-HabitatSpawnEntry resource" % String(content_id))
            continue
        var entry: HabitatSpawnEntry = entry_resource as HabitatSpawnEntry
        errors.append_array(entry.validate_entry())
    if max_creatures_alive < 1:
        errors.append("Habitat %s max_creatures_alive must be >= 1" % String(content_id))
    if initial_creatures < 0:
        errors.append("Habitat %s initial_creatures must be >= 0" % String(content_id))
    if initial_creatures > max_creatures_alive:
        errors.append("Habitat %s initial_creatures cannot exceed max_creatures_alive" % String(content_id))
    if respawn_delay_seconds <= 0.0:
        errors.append("Habitat %s respawn_delay_seconds must be positive" % String(content_id))
    return errors

func is_region_zone_compatible(region_definition: RegionDefinition, zone_definition: ZoneDefinition) -> bool:
    if region_definition == null or zone_definition == null:
        return false
    for required_tag: StringName in required_region_tags:
        if not region_definition.region_tags.has(required_tag):
            return false
    for required_tag: StringName in required_zone_tags:
        if not zone_definition.zone_tags.has(required_tag):
            return false
    return true
