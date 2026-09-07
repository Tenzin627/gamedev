extends ContentDefinition
class_name CreatureEvolutionDefinition

@export var source_species_id: StringName = &""
@export_enum("baby", "teen") var source_stage: String = "baby"
@export var result_species_id: StringName = &""
@export_enum("teen", "adult") var result_stage: String = "teen"
@export_range(0, 999999, 1) var min_growth_xp: int = 0
@export_range(0, 999, 1) var min_bond_level: int = 0
@export_enum("None", "Attack", "Speed", "Guard") var required_tendency: String = "None"
@export_range(0, 9999, 1) var minimum_tendency: int = 0
@export var branch_label: String = "Evolution"
@export_multiline var preview_note: String = ""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if source_species_id == &"":
        errors.append("Evolution %s is missing source_species_id" % String(content_id))
    if result_species_id == &"":
        errors.append("Evolution %s is missing result_species_id" % String(content_id))
    if source_species_id == result_species_id and source_species_id != &"":
        errors.append("Evolution %s source and result species must differ" % String(content_id))
    if source_stage == result_stage:
        errors.append("Evolution %s source and result stages must differ" % String(content_id))
    if source_stage == "baby" and result_stage != "teen":
        errors.append("Evolution %s must progress baby -> teen" % String(content_id))
    if source_stage == "teen" and result_stage != "adult":
        errors.append("Evolution %s must progress teen -> adult" % String(content_id))
    if required_tendency == "None" and minimum_tendency > 0:
        errors.append("Evolution %s has a tendency threshold without a required tendency" % String(content_id))

    var source_species: CreatureSpeciesDefinition = ContentDB.get_definition(source_species_id) as CreatureSpeciesDefinition
    if source_species == null and source_species_id != &"":
        errors.append("Evolution %s source species does not exist: %s" % [String(content_id), String(source_species_id)])
    elif source_species != null and source_species.life_stage.to_lower() != source_stage:
        errors.append("Evolution %s source stage %s does not match species stage %s" % [String(content_id), source_stage, source_species.life_stage.to_lower()])

    var result_species: CreatureSpeciesDefinition = ContentDB.get_definition(result_species_id) as CreatureSpeciesDefinition
    if result_species == null and result_species_id != &"":
        errors.append("Evolution %s result species does not exist: %s" % [String(content_id), String(result_species_id)])
    elif result_species != null and result_species.life_stage.to_lower() != result_stage:
        errors.append("Evolution %s result stage %s does not match species stage %s" % [String(content_id), result_stage, result_species.life_stage.to_lower()])
    return errors

func get_required_tendency_key() -> String:
    if required_tendency == "None":
        return ""
    return required_tendency.to_lower()
