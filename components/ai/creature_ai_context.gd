extends RefCounted
class_name CreatureAIContext

var body: CharacterBody2D = null
var habitat: HabitatArea2D = null
var perception: CreaturePerceptionComponent = null
var profile: CreatureAIProfileDefinition = null
var rng: RandomNumberGenerator = null
var home_position: Vector2 = Vector2.ZERO

func get_player() -> Node2D:
    if perception == null:
        return null
    return perception.get_nearest_target()

func get_player_distance() -> float:
    if perception == null:
        return INF
    return perception.get_nearest_target_distance()

func is_inside_habitat() -> bool:
    if body == null or habitat == null:
        return true
    return habitat.contains_global_position(body.global_position)
