extends ItemDefinition
class_name CreatureFoodDefinition

@export_range(0, 9999, 1) var growth_xp: int = 0
@export_range(0, 99, 1) var bond_growth: int = 0
@export_range(0, 999, 1) var attack_tendency: int = 0
@export_range(0, 999, 1) var speed_tendency: int = 0
@export_range(0, 999, 1) var guard_tendency: int = 0
@export var unlock_move_ids: Array[StringName] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if category != "Food":
        errors.append("Creature food %s must use Food category" % String(content_id))
    if growth_xp <= 0 and bond_growth <= 0 and attack_tendency <= 0 and speed_tendency <= 0 and guard_tendency <= 0 and unlock_move_ids.is_empty():
        errors.append("Creature food %s has no creature progression effect" % String(content_id))

    var seen_moves: Dictionary = {}
    for move_id: StringName in unlock_move_ids:
        if move_id == &"":
            errors.append("Creature food %s contains an empty unlock move ID" % String(content_id))
            continue
        if seen_moves.has(move_id):
            errors.append("Creature food %s repeats unlock move %s" % [String(content_id), String(move_id)])
            continue
        seen_moves[move_id] = true
        if not ContentDB.get_definition(move_id) is MoveDefinition:
            errors.append("Creature food %s references missing/non-move content %s" % [String(content_id), String(move_id)])
    return errors
