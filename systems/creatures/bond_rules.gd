extends RefCounted
class_name BondRules

const DEFAULT_RETRY_COST: int = 25

static func calculate_bond_chance(species: CreatureSpeciesDefinition, health_ratio: float = 1.0, situational_bonus: float = 0.0) -> float:
    if species == null:
        return 0.0
    var weakened_bonus: float = clampf(1.0 - health_ratio, 0.0, 1.0) * 0.25
    return clampf(species.base_bond_chance + weakened_bonus + situational_bonus, 0.05, 0.95)

static func roll_success(chance: float, seed_text: String) -> bool:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    var seed_value: int = seed_text.hash()
    if seed_value < 0:
        seed_value = -seed_value
    rng.seed = seed_value
    return rng.randf() <= clampf(chance, 0.0, 1.0)
