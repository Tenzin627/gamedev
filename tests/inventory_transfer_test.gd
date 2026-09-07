extends Node

var failures: Array[String] = []

func check(value: bool, label: String) -> void:
    print(("PASS " if value else "FAIL ") + label)
    if not value:
        failures.append(label)

func _ready() -> void:
    var pack: InventoryComponent = InventoryComponent.new()
    pack.sync_with_game_session = false
    pack.slot_capacity = 4
    add_child(pack)
    var hotbar: HotbarComponent = HotbarComponent.new()
    hotbar.sync_with_game_session = false
    hotbar.slot_count = 2
    add_child(hotbar)
    var chest: StorageContainerComponent = StorageContainerComponent.new()
    chest.slot_capacity = 3
    add_child(chest)
    await get_tree().process_frame

    check(pack.add_item(&"item.material.basin_wood", 99) == 0, "Pack accepts a full stack")
    check(pack.transfer_slot_to(0, hotbar, 0), "Pack to hotbar")
    check(hotbar.get_quantity_at(0) == 99 and pack.get_stack_at(0) == null, "Empty-slot move preserves quantity")
    check(hotbar.transfer_slot_to(0, pack, 0), "Hotbar to pack")

    chest.add_item(&"item.material.basin_wood", 90)
    check(pack.transfer_slot_to(0, chest, 0), "Matching stacks partially merge")
    check(chest.get_quantity_at(0) == 99 and pack.get_quantity_at(0) == 90, "Partial merge preserves remainder")
    check(not pack.transfer_slot_to(0, chest, 0), "Full destination rejects merge")

    hotbar.add_item(&"item.tool.field_hoe", 1)
    check(pack.transfer_slot_to(0, hotbar, 0), "Different items swap")
    check(hotbar.get_item_id(0) == &"item.material.basin_wood", "Swap updates destination")
    check(pack.get_item_id(0) == &"item.tool.field_hoe", "Swap returns destination item to source")
    check(not pack.transfer_slot_to(-1, chest, 0), "Invalid source index rejected")
    check(not pack.transfer_slot_to(0, chest, 99), "Invalid target index rejected")

    hotbar.clear_all()
    pack.clear()
    pack.add_item(&"item.seed.moonroot", 5)
    check(pack.transfer_amount_to_first_available(0, hotbar, 1), "Single-item transfer")
    check(pack.get_quantity_at(0) == 4 and hotbar.get_quantity_at(0) == 1, "Single-item transfer preserves total")
    check(pack.transfer_slot_to_first_available(0, hotbar), "Quick transfer finds matching slot")
    check(hotbar.get_quantity_at(0) == 5, "Quick transfer merges matching stack")

    pack.clear()
    chest.clear_all_slots()
    pack.add_item(&"item.material.basin_wood", 20)
    chest.add_item(&"item.material.basin_wood", 95)
    check(pack.transfer_amount_to_first_available(0, chest, 10), "Amount transfer spans partial stack and empty slot")
    check(chest.get_quantity_at(0) == 99 and chest.get_quantity_at(1) == 6 and pack.get_quantity_at(0) == 10, "Partial stack plus empty slot preserves requested amount")

    pack.clear()
    chest.clear_all_slots()
    pack.add_item(&"item.material.basin_wood", 10)
    chest.replace_stack_at(0, ItemStack.new(&"item.material.basin_wood", 95))
    chest.replace_stack_at(1, ItemStack.new(&"item.material.basin_wood", 96))
    check(pack.transfer_amount_to_first_available(0, chest, 7), "Amount transfer spans multiple partial stacks")
    check(chest.get_quantity_at(0) == 99 and chest.get_quantity_at(1) == 99 and pack.get_quantity_at(0) == 3, "Multiple partial stacks preserve total and remainder")

    pack.clear()
    chest.clear_all_slots()
    pack.add_item(&"item.material.basin_wood", 10)
    chest.replace_stack_at(0, ItemStack.new(&"item.material.basin_wood", 98))
    chest.replace_stack_at(1, ItemStack.new(&"item.material.basin_wood", 99))
    chest.replace_stack_at(2, ItemStack.new(&"item.field_poultice", 1))
    check(not pack.transfer_amount_to_first_available(0, chest, 5), "Insufficient total capacity rejects transfer")
    check(pack.get_quantity_at(0) == 10 and chest.get_quantity_at(0) == 98 and chest.get_quantity_at(1) == 99, "Rejected transfer is atomic")

    pack.clear()
    chest.clear_all_slots()
    pack.add_item(&"item.material.basin_wood", 5)
    check(pack.transfer_amount_to_first_available(0, chest, 20), "Requested amount caps at source quantity")
    check(pack.get_stack_at(0) == null and chest.get_total_quantity(&"item.material.basin_wood") == 5, "Capped transfer moves all available source items")

    GameSession.set_value(&"inventory_slots", {"slots": []})
    GameSession.set_value(&"hotbar", hotbar.export_state())
    check(ContentConditionEvaluator._get_inventory_quantity(&"item.seed.moonroot") == 5, "Quest count includes hotbar")

    var exported: Dictionary = hotbar.export_state()
    hotbar.clear_all()
    hotbar.import_state(exported)
    check(hotbar.get_quantity_at(0) == 5, "Transfer state survives export/import")

    pack.import_state({
        "slot_capacity": 4,
        "slots": [{"item_id": "item.material.basin_wood", "quantity": 120}],
    })
    check(pack.get_total_quantity(&"item.material.basin_wood") == 120, "Oversized imported stack is redistributed without loss")
    pack.replace_stack_at(3, ItemStack.new(&"item.seed.moonroot", 1))
    pack.configure_slots(2)
    check(pack.get_slot_count() == 4 and pack.get_item_id(3) == &"item.seed.moonroot", "Occupied slots prevent destructive capacity shrink")

    pack.clear()
    hotbar.clear_all()
    hotbar.add_item(&"item.field_poultice", 2)
    check(CarriedInventoryService.has_item(pack, &"item.field_poultice", 2, hotbar), "Carried inventory includes Quick Bar")
    check(CarriedInventoryService.remove_item(pack, &"item.field_poultice", 1, hotbar) == 0, "Carried inventory consumes Quick Bar item")
    check(hotbar.get_total_quantity(&"item.field_poultice") == 1, "Quick Bar consumption preserves remainder")

    GameSession.session_state["recipe_unlocks"] = ["recipe.test.legacy"]
    GameSession.session_state["discovered_recipes"] = []
    GameSession._migrate_legacy_keys()
    check(Array(GameSession.get_value(&"discovered_recipes", [])).has("recipe.test.legacy"), "Legacy recipe discovery migrates")
    check(not GameSession.session_state.has("recipe_unlocks"), "Obsolete recipe key is removed")

    print("INVENTORY TRANSFER TEST: %s (%d failures)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if failures.is_empty() else 1)
