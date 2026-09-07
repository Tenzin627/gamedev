extends RefCounted
class_name BattleAction

const TYPE_MOVE: StringName = &"move"
const TYPE_SWITCH: StringName = &"switch"
const TYPE_ITEM: StringName = &"item"
const TYPE_ESCAPE: StringName = &"escape"
const TYPE_BOND: StringName = &"bond"

var action_type: StringName = &""
var side_id: StringName = &""
var actor_id: String = ""
var move_id: StringName = &""
var switch_index: int = -1
var item_id: StringName = &""
var target_index: int = -1

static func move_action(side: StringName, actor: BattleCreatureState, selected_move_id: StringName) -> BattleAction:
    var action: BattleAction = BattleAction.new()
    action.action_type = TYPE_MOVE
    action.side_id = side
    action.actor_id = "" if actor == null else actor.battle_actor_id
    action.move_id = selected_move_id
    return action

static func switch_action(side: StringName, actor: BattleCreatureState, target_index: int) -> BattleAction:
    var action: BattleAction = BattleAction.new()
    action.action_type = TYPE_SWITCH
    action.side_id = side
    action.actor_id = "" if actor == null else actor.battle_actor_id
    action.switch_index = target_index
    return action

static func item_action(side: StringName, actor: BattleCreatureState, selected_item_id: StringName, selected_target_index: int) -> BattleAction:
    var action: BattleAction = BattleAction.new()
    action.action_type = TYPE_ITEM
    action.side_id = side
    action.actor_id = "" if actor == null else actor.battle_actor_id
    action.item_id = selected_item_id
    action.target_index = selected_target_index
    return action

static func bond_action(side: StringName, actor: BattleCreatureState) -> BattleAction:
    var action: BattleAction = BattleAction.new()
    action.action_type = TYPE_BOND
    action.side_id = side
    action.actor_id = "" if actor == null else actor.battle_actor_id
    return action

static func escape_action(side: StringName, actor: BattleCreatureState) -> BattleAction:
    var action: BattleAction = BattleAction.new()
    action.action_type = TYPE_ESCAPE
    action.side_id = side
    action.actor_id = "" if actor == null else actor.battle_actor_id
    return action
