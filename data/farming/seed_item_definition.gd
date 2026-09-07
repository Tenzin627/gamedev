extends ItemDefinition
class_name SeedItemDefinition

@export var crop_id: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if category != "Seed":
        errors.append("SeedItemDefinition category must be Seed for %s" % String(content_id))
    if crop_id == &"":
        errors.append("SeedItemDefinition missing crop_id for %s" % String(content_id))
    elif not ContentDB.has_definition(crop_id):
        errors.append("SeedItemDefinition crop missing: %s" % String(crop_id))
    return errors
