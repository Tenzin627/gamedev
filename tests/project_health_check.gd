extends Node

func _ready() -> void:
    var failures: Array[String] = []
    _check_content(failures)
    _check_ai(failures)
    await _check_battle(failures)
    await _check_battle_presentation(failures)
    _check_battle_bond(failures)
    if failures.is_empty():
        print("LUNG SA PROJECT HEALTH CHECK: PASS")
    else:
        for failure: String in failures:
            push_error("PROJECT HEALTH: %s" % failure)

func _check_content(failures: Array[String]) -> void:
    var content_errors: PackedStringArray = ContentDB.get_last_errors()
    for content_error: String in content_errors:
        failures.append("ContentDB: %s" % content_error)
    _expect(ContentDB.get_definition(&"creature.mossback.baby") is CreatureSpeciesDefinition, "Mossback definition missing", failures)
    _expect(ContentDB.get_definition(&"creature.rillfin.baby") is CreatureSpeciesDefinition, "Rillfin definition missing", failures)
    _expect(ContentDB.get_definition(&"battle_rules.standard") is BattleRulesetDefinition, "standard battle rules missing", failures)
    _expect(ContentDB.get_definition(&"battle_effect.heal.12_ally") is BattleEffectDefinition, "battle heal effect missing", failures)
    _expect(ContentDB.get_definition(&"item.field_poultice") is BattleConsumableDefinition, "battle consumable missing", failures)
    _expect(ContentDB.get_definition(&"spell.bond") is BondSpellDefinition, "Bond spell missing", failures)
    _expect(ContentDB.get_definition(&"npc.central_basin.mei") is NPCDefinition, "Mei NPC definition missing", failures)
    _expect(ContentDB.get_definition(&"dialogue.central_basin.mei_demo") is DialogueDefinition, "Phase 6 Mei dialogue missing", failures)
    _expect(ContentDB.get_definition(&"shop.central_basin.demo_supplies") is ShopDefinition, "foundation shop definition missing", failures)
    _expect(ContentDB.get_definition(&"crop.moonroot") is CropDefinition, "Moonroot crop definition missing", failures)
    _expect(ContentDB.get_definition(&"item.seed.moonroot") is SeedItemDefinition, "Moonroot seed definition missing", failures)
    _expect(ContentDB.get_definition(&"item.tool.field_hoe") is ToolDefinition, "Field Hoe missing", failures)
    _expect(ContentDB.get_definition(&"item.tool.watering_can") is ToolDefinition, "Watering Can missing", failures)
    _expect(ContentDB.get_definition(&"item.tool.field_axe") is ToolDefinition, "Field Axe missing", failures)
    _expect(ContentDB.get_definition(&"item.tool.field_pickaxe") is ToolDefinition, "Field Pickaxe missing", failures)
    _expect(ContentDB.get_definition(&"plant.central_basin.wild_herb") is PlantDefinition, "Wild Herb plant definition missing", failures)
    _expect(ContentDB.get_definition(&"crop.sunpod") is CropDefinition, "Sunpod crop definition missing", failures)
    _expect(ContentDB.get_definition(&"item.material.plant_fiber") is ItemDefinition, "Plant Fiber item definition missing", failures)
    _expect(ContentDB.get_definition(&"shop.central_basin.farm_shipping") is ShopDefinition, "Farm Shipping shop definition missing", failures)
    _expect(ContentDB.get_active_profile() is GameProfileDefinition, "active designer game profile missing", failures)
    _expect(ContentDB.get_definition(&"farm_work.mossback") is FarmWorkProfileDefinition, "Mossback farm work profile missing", failures)
    _expect(ContentDB.get_definition(&"farm_work.rillfin") is FarmWorkProfileDefinition, "Rillfin farm work profile missing", failures)
    _expect(ContentDB.get_definition(&"farm_work.brambleback") is FarmWorkProfileDefinition, "Brambleback farm work profile missing", failures)
    _expect(ContentDB.get_definition(&"quest.central_basin.receipt_that_bites_back") is QuestDefinition, "Phase 6 main quest missing", failures)
    _expect(ContentDB.get_definition(&"quest.central_basin.lucky_bowl") is QuestDefinition, "Phase 6 wager quest missing", failures)
    _expect(ContentDB.get_definition(&"story_chain.central_basin.first_collection") is StoryChainDefinition, "Phase 6 story chain missing", failures)
    _expect(ContentDB.get_definition(&"dialogue.central_basin.ledger_clerk_demo") is DialogueDefinition, "Phase 6 Ledger dialogue missing", failures)
    _expect(ContentDB.get_definition(&"dialogue.central_basin.tavi_receipt_demo") is DialogueDefinition, "Phase 6 Tavi dialogue missing", failures)
    _expect(ContentDB.get_definition(&"dialogue.central_basin.pao_wager_demo") is DialogueDefinition, "Phase 6 Pao dialogue missing", failures)
    _expect(ContentDB.get_definition(&"loot.central_basin.tree") is LootTableDefinition, "tree loot table missing", failures)
    _expect(ContentDB.get_definition(&"loot.central_basin.rock") is LootTableDefinition, "rock loot table missing", failures)
    _expect(ContentDB.get_definition(&"story_chain.central_basin.living_roads") == null, "retired Living Roads story content still registered", failures)
    _expect(ContentDB.get_definition(&"item.tool.trail_axe") == null, "retired Trail Axe content still registered", failures)
    _expect(ContentDB.get_count() >= 90, "ContentDB auto-registration count is unexpectedly low", failures)

func _check_ai(failures: Array[String]) -> void:
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(&"creature.mossback.baby") as CreatureSpeciesDefinition
    if species == null:
        return
    _expect(ContentDB.get_definition(species.ai_profile_id) is CreatureAIProfileDefinition, "Mossback AI profile missing", failures)

func _check_battle(failures: Array[String]) -> void:
    var model: BattleStateModel = BattleStateFactory.create_debug_model()
    _expect(model != null and model.is_valid_setup(), "debug battle state invalid", failures)
    if model == null or not model.is_valid_setup():
        return
    model.begin_battle()
    var inventory: InventoryComponent = InventoryComponent.new()
    inventory.sync_with_game_session = false
    add_child(inventory)
    await get_tree().process_frame
    inventory.clear()
    inventory.add_item(&"item.field_poultice", 1)
    var hotbar: HotbarComponent = HotbarComponent.new()
    hotbar.sync_with_game_session = false
    add_child(hotbar)
    await get_tree().process_frame
    inventory.transfer_slot_to_first_available(0, hotbar)
    var resolver: BattleTurnResolver = BattleTurnResolver.new()
    resolver.set_player_inventory(inventory, hotbar)
    resolver.begin_battle_effects(model)
    var active: BattleCreatureState = model.get_player_active()
    if active != null:
        active.current_hp = maxi(active.current_hp - 8, 1)
        var hp_before: int = active.current_hp
        var action: BattleAction = BattleAction.item_action(&"player", active, &"item.field_poultice", model.player_team.active_index)
        resolver.resolve_round(model, action, null)
        _expect(active.current_hp > hp_before, "battle item healing failed", failures)
        _expect(CarriedInventoryService.get_total_quantity(inventory, &"item.field_poultice", hotbar) == 0, "battle Quick Bar item consumption failed", failures)
    inventory.queue_free()
    hotbar.queue_free()


func _check_battle_presentation(failures: Array[String]) -> void:
    var hud_scene: PackedScene = load("res://ui/battle/battle_hud.tscn") as PackedScene
    var battle_scene_resource: PackedScene = load("res://world/battle/battle_scene.tscn") as PackedScene
    _expect(hud_scene != null, "battle HUD scene missing", failures)
    _expect(battle_scene_resource != null, "battle scene missing", failures)
    if hud_scene == null:
        return
    var hud: Node = hud_scene.instantiate()
    add_child(hud)
    await get_tree().process_frame
    _expect(hud.get_node_or_null("OpponentStatus") is BattleCreatureStatusWidget, "opponent status widget missing", failures)
    _expect(hud.get_node_or_null("PlayerStatus") is BattleCreatureStatusWidget, "player status widget missing", failures)
    _expect(hud.get_node_or_null("CommandMenu") is BattleCommandMenu, "battle command menu missing", failures)
    _expect(hud.get_node_or_null("ActionPicker") is BattleActionPicker, "battle action picker missing", failures)
    _expect(hud.get_node_or_null("CombatFeed") is PanelContainer, "battle combat feed missing", failures)
    _expect(hud.get_node_or_null("BondEncounterPanel") is BondEncounterPanel, "battle Bond panel missing", failures)
    var command_menu: BattleCommandMenu = hud.get_node_or_null("CommandMenu") as BattleCommandMenu
    if command_menu != null:
        _expect(command_menu.get_node_or_null("Margin/VBox/Grid/Bond") is Button, "battle Bond command missing", failures)
    hud.queue_free()

func _check_battle_bond(failures: Array[String]) -> void:
    var model: BattleStateModel = BattleStateFactory.create_debug_model()
    _expect(model != null, "Bond test battle model missing", failures)
    if model == null:
        return
    model.encounter_kind = &"wild"
    model.begin_battle()
    var service: BattleBondService = BattleBondService.new()
    var info: Dictionary = service.get_attempt_info(model)
    _expect(bool(info.get("available", false)), "Bond service should be available in a wild battle", failures)
    _expect(float(info.get("chance", 0.0)) > 0.0, "Bond chance should be positive", failures)
    _expect(not model.bond_standard_attempt_used, "standard Bond attempt should begin unused", failures)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
