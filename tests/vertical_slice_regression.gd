extends Node
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
    if not value: failures.append(label)
    print(("PASS " if value else "FAIL ")+label)
func _ready() -> void:
    GameSession.set_value(&"slice.welcomed",true)
    await get_tree().process_frame
    var scene: PackedScene = load("res://world/central_basin/zones/demo_farm.tscn")
    var region: RegionRoot = scene.instantiate()
    add_child(region)
    await get_tree().process_frame
    await get_tree().process_frame
    var player: PlayerActor = region.get_node("PlayerActor")
    var farm: FarmPlotSystem = region.get_local_system(&"FarmPlotSystem")
    var farm_visual: FarmPlotVisual = region.get_node("Environment/HomeFarmPlots") as FarmPlotVisual
    var crop: CropDefinition = ContentDB.get_definition(&"crop.moonroot") as CropDefinition
    # Isolate this regression from any runtime farm state restored while the scene binds.
    # Starter ownership is rebuilt from designer-authored StarterPlots by the farm system.
    farm.import_runtime_state({})
    var owned_cells: Array[Vector2i] = farm.get_owned_cells()
    check(not owned_cells.is_empty(),"Farm exposes at least one owned starter plot")
    if owned_cells.is_empty():
        get_tree().quit(1)
        return
    var cell: Vector2i = owned_cells[0]
    check(farm_visual != null,"Farm presentation exists")
    check(farm_visual.get_farm_layers().size()==5,"Farm uses five authoring/runtime TileMapLayer nodes")
    check(farm_visual.farm_owned_plots.get_cell_source_id(cell)==FarmPlotVisual.SOURCE_UNTILLED,"Owned plot is an untilled tile")
    check(farm_visual.get_children().all(func(child: Node) -> bool: return child is TileMapLayer),"Farm renderer contains only tile layers")
    check(not farm.plant(cell,crop),"Cannot plant untilled land")
    check(not farm.till(Vector2i(-1,0)),"Cannot till outside owned land")
    check(farm.till(cell),"Till owned plot")
    check(farm_visual.farm_soil.get_cell_source_id(cell)==FarmPlotVisual.SOURCE_TILLED,"Tilling updates FarmSoil layer")
    check(not farm.till(cell),"Duplicate till rejected")
    check(farm.plant(cell,crop),"Plant valid Moonroot")
    check(farm_visual.farm_crops.get_cell_source_id(cell)==crop.get_farm_tile_source(0,false),"Planting creates crop-stage tile")
    check(not farm.plant(cell,crop),"Occupied plot rejects seed")
    WorldTimeService.advance_minutes(1440)
    check(int(farm.get_plot(cell).get("stage",-1))==0,"Dry crop does not grow")
    for i: int in range(3):
        check(farm.water(cell),"Water growth day %d" % i)
        check(farm_visual.farm_soil.get_cell_source_id(cell)==FarmPlotVisual.SOURCE_WATERED,"Watering updates FarmSoil tile %d" % i)
        check(not farm.water(cell),"Duplicate water rejected %d" % i)
        WorldTimeService.advance_minutes(1440)
        check(not bool(farm.get_plot(cell).get("watered",true)),"Water clears each morning %d" % i)
        check(int(farm.get_plot(cell).get("stage",-1))==i+1,"Growth advances exactly once %d" % i)
        check(farm_visual.farm_crops.get_cell_source_id(cell)==crop.get_farm_tile_source(i+1,false),"Growth updates FarmCrops tile %d" % i)
    check(bool(farm.get_plot(cell).get("ready",false)),"Harvest ready after 3 watered nights")
    check(farm_visual.farm_crops.get_cell_source_id(cell)==crop.get_farm_tile_source(int(farm.get_plot(cell).get("stage",0)),true),"Ready crop uses harvest tile")
    var full_pack: InventoryComponent = InventoryComponent.new()
    full_pack.slot_capacity = 1
    full_pack.sync_with_game_session = false
    add_child(full_pack)
    full_pack.add_item(&"item.tool.field_hoe",1)
    check(farm.harvest_to_container(cell,full_pack)==0,"Full inventory rejects harvest")
    check(bool(farm.get_plot(cell).get("ready",false)),"Full inventory preserves ready crop")
    full_pack.queue_free()
    player.global_position = farm.farm_cell_to_world_center(cell)-Vector2(0,72)
    player.animation_component.set_motion(false,Vector2.DOWN)
    player.hotbar_component.select_slot(0)
    var before: int = player.inventory_component.get_total_quantity(&"item.plant.moonroot")
    check(player.farm_interaction_component.try_farm_action(),"Harvest handled with Hoe selected")
    check(player.inventory_component.get_total_quantity(&"item.plant.moonroot")>before,"Harvest delivered to Pack")
    check(not bool(farm.get_plot(cell).get("ready",false)),"Cannot harvest twice")
    check(farm_visual.farm_crops.get_cell_source_id(cell)==-1,"Harvest clears FarmCrops tile")
    check(farm.is_tilled(cell),"Soil retained for replanting")
    # A real seed action must remove exactly one item.
    player.hotbar_component.select_slot(4)
    var seeds: int = player.hotbar_component.get_total_quantity(&"item.seed.moonroot")
    check(player.farm_interaction_component.try_farm_action(),"Plant through player interaction")
    check(player.hotbar_component.get_total_quantity(&"item.seed.moonroot")==seeds-1,"Exactly one seed consumed")
    player.farm_interaction_component.try_farm_action()
    check(player.hotbar_component.get_total_quantity(&"item.seed.moonroot")==seeds-1,"Failed planting consumes no seed")
    farm.water(cell)
    check(SaveService.save_slot(97)==OK,"Save current live farm")
    farm.import_runtime_state({})
    check(SaveService.load_slot(97)==OK,"Load saved snapshot")
    region.restore_runtime_state()
    check(bool(farm.get_plot(cell).get("watered",false)),"Water and planted crop restored")
    check(not String(farm.get_plot(cell).get("crop_id","")).is_empty(),"Crop identity restored")
    SaveService.delete_slot(97)
    check(region.get_tile_layer(&"Ground").get_used_cells().size()>500,"Ground has real tile cells")
    check(region.get_tile_layer(&"Water").get_used_cells().size()>0,"Water has real tile cells")
    check(region.get_tile_layer(&"Water").tile_set.get_physics_layer_collision_layer(0)==1,"Water blocks actor collision")
    var count_before: int = player.hotbar_component.get_total_quantity(&"item.seed.moonroot")
    DemoBootstrap._starter_seeded = false
    DemoBootstrap._seed_player_loadout(ContentDB.get_active_profile())
    check(player.hotbar_component.get_total_quantity(&"item.seed.moonroot")==count_before,"Travel cannot refill seed supply")
    region.persist_runtime_state = false
    region.queue_free()
    await get_tree().process_frame
    var river: RegionRoot = load("res://world/central_basin/zones/demo_wilds.tscn").instantiate()
    add_child(river)
    await get_tree().process_frame
    check(river.get_tile_layer(&"TerrainStructure").get_cell_source_id(Vector2i(-1,1))==7,"River crossing has bridge deck")
    check(river.get_tile_layer(&"Water").get_cell_source_id(Vector2i(-1,1))==-1,"Bridge crossing has no hidden water collision")
    river.persist_runtime_state = false
    river.queue_free()
    await get_tree().process_frame
    print("VERTICAL SLICE REGRESSION: %s (%d failures)" % ["PASS" if failures.is_empty() else "FAIL",failures.size()])
    await get_tree().create_timer(0.2).timeout
    get_tree().quit(0 if failures.is_empty() else 1)
