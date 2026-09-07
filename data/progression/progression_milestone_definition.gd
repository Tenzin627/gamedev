extends ContentDefinition
class_name ProgressionMilestoneDefinition

@export var track_id: StringName = &""
@export_range(0, 999, 1) var rank: int = 0
@export var required_points: int = 0
@export var unlock_tags: Array[StringName] = []
@export var reward_currency: int = 0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if track_id == &"":
        errors.append("Progression milestone %s requires track_id" % String(content_id))
    if required_points < 0 or reward_currency < 0:
        errors.append("Progression milestone %s cannot use negative requirements/rewards" % String(content_id))
    return errors
