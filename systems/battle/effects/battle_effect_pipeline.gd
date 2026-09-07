extends RefCounted
class_name BattleEffectPipeline

func apply_effect_ids(model: BattleStateModel, source: BattleCreatureState, primary_target: BattleCreatureState, effect_ids: Array[StringName], selected_ally: BattleCreatureState = null) -> Array[String]:
    var messages: Array[String] = []
    for effect_id: StringName in effect_ids:
        var definition: BattleEffectDefinition = ContentDB.get_definition(effect_id) as BattleEffectDefinition
        if definition == null:
            messages.append("Missing battle effect: %s" % String(effect_id))
            continue
        var target: BattleCreatureState = _resolve_target(definition, source, primary_target, selected_ally)
        if target == null:
            continue
        var message: String = _apply_definition(model, source, target, definition)
        if not message.is_empty():
            messages.append(message)
    return messages

func trigger_trait(model: BattleStateModel, creature: BattleCreatureState, trigger_name: StringName, opponent: BattleCreatureState = null) -> Array[String]:
    var messages: Array[String] = []
    if creature == null or creature.active_trait_id == &"":
        return messages
    var trait_definition: TraitDefinition = ContentDB.get_definition(creature.active_trait_id) as TraitDefinition
    if trait_definition == null or trait_definition.trigger != trigger_name:
        return messages
    var effect_messages: Array[String] = apply_effect_ids(model, creature, opponent, trait_definition.effect_ids, creature)
    if not effect_messages.is_empty():
        messages.append("%s's %s activated." % [creature.display_name, trait_definition.display_name])
        messages.append_array(effect_messages)
    return messages

func tick_statuses(creature: BattleCreatureState) -> Array[String]:
    var messages: Array[String] = []
    if creature == null or creature.is_fainted():
        return messages
    var remaining_statuses: Array[StringName] = []
    var remaining_turns: Dictionary = {}
    for status_id: StringName in creature.status_effect_ids:
        var definition: BattleStatusDefinition = ContentDB.get_definition(status_id) as BattleStatusDefinition
        if definition == null:
            continue
        var turns: int = int(creature.status_turns_remaining.get(status_id, definition.default_duration_turns))
        if definition.damage_each_turn > 0:
            var damage: int = mini(definition.damage_each_turn, creature.current_hp)
            creature.current_hp = maxi(creature.current_hp - damage, 0)
            messages.append("%s suffered %d damage from %s." % [creature.display_name, damage, definition.display_name])
        if definition.healing_each_turn > 0 and not creature.is_fainted():
            var before_hp: int = creature.current_hp
            creature.current_hp = mini(creature.current_hp + definition.healing_each_turn, creature.max_hp)
            var healed: int = creature.current_hp - before_hp
            if healed > 0:
                messages.append("%s recovered %d HP from %s." % [creature.display_name, healed, definition.display_name])
        turns -= 1
        if turns > 0 and not creature.is_fainted():
            remaining_statuses.append(status_id)
            remaining_turns[status_id] = turns
        else:
            messages.append("%s is no longer affected by %s." % [creature.display_name, definition.display_name])
    creature.status_effect_ids = remaining_statuses
    creature.status_turns_remaining = remaining_turns
    return messages

func get_status_power_modifier(creature: BattleCreatureState) -> int:
    var total: int = 0
    if creature == null:
        return total
    for status_id: StringName in creature.status_effect_ids:
        var definition: BattleStatusDefinition = ContentDB.get_definition(status_id) as BattleStatusDefinition
        if definition != null:
            total += definition.power_modifier
    return total

func get_status_priority_modifier(creature: BattleCreatureState) -> int:
    var total: int = 0
    if creature == null:
        return total
    for status_id: StringName in creature.status_effect_ids:
        var definition: BattleStatusDefinition = ContentDB.get_definition(status_id) as BattleStatusDefinition
        if definition != null:
            total += definition.priority_modifier
    return total

func get_status_damage_taken_multiplier(creature: BattleCreatureState) -> float:
    var total: float = 1.0
    if creature == null:
        return total
    for status_id: StringName in creature.status_effect_ids:
        var definition: BattleStatusDefinition = ContentDB.get_definition(status_id) as BattleStatusDefinition
        if definition != null:
            total *= definition.damage_taken_multiplier
    return total

func _resolve_target(definition: BattleEffectDefinition, source: BattleCreatureState, primary_target: BattleCreatureState, selected_ally: BattleCreatureState) -> BattleCreatureState:
    if definition.target_scope == "Self":
        return source
    if definition.target_scope == "SelectedAlly":
        return selected_ally if selected_ally != null else source
    return primary_target

func _apply_definition(_model: BattleStateModel, _source: BattleCreatureState, target: BattleCreatureState, definition: BattleEffectDefinition) -> String:
    if definition.effect_type == "Damage":
        var damage: int = maxi(definition.amount, 0)
        target.current_hp = maxi(target.current_hp - damage, 0)
        return "%s took %d effect damage." % [target.display_name, damage]
    if definition.effect_type == "Heal":
        var before_hp: int = target.current_hp
        target.current_hp = mini(target.current_hp + maxi(definition.amount, 0), target.max_hp)
        return "%s recovered %d HP." % [target.display_name, target.current_hp - before_hp]
    if definition.effect_type == "Guard":
        target.guarding = true
        return "%s is guarding." % target.display_name
    if definition.effect_type == "PowerModifier":
        target.power_modifier += definition.amount
        return "%s's power changed by %d." % [target.display_name, definition.amount]
    if definition.effect_type == "DamageTakenModifier":
        target.damage_taken_multiplier *= definition.multiplier
        return "%s's resilience shifted." % target.display_name
    if definition.effect_type == "PriorityModifier":
        target.priority_modifier += definition.amount
        return "%s's action priority changed by %d." % [target.display_name, definition.amount]
    if definition.effect_type == "ApplyStatus":
        if not target.status_effect_ids.has(definition.status_id):
            target.status_effect_ids.append(definition.status_id)
        var status_definition: BattleStatusDefinition = ContentDB.get_definition(definition.status_id) as BattleStatusDefinition
        var duration: int = definition.status_duration_turns
        if duration <= 0 and status_definition != null:
            duration = status_definition.default_duration_turns
        target.status_turns_remaining[definition.status_id] = maxi(duration, 1)
        var status_name: String = String(definition.status_id) if status_definition == null else status_definition.display_name
        return "%s gained %s." % [target.display_name, status_name]
    if definition.effect_type == "Cleanse":
        var removed_count: int = target.status_effect_ids.size()
        target.status_effect_ids.clear()
        target.status_turns_remaining.clear()
        return "%s cleared %d status effect(s)." % [target.display_name, removed_count]
    return ""
