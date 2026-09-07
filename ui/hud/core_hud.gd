extends CanvasLayer
class_name CoreHUD

signal gameplay_block_changed(blocked: bool)
signal inventory_item_activated(slot_index: int, item_id: StringName)
signal confirmation_resolved(context_id: StringName, accepted: bool)
signal waymark_destination_selected(waymark_id: StringName)
signal slice_restart_requested

@onready var root: Control = $Root
@onready var hotbar_widget: HotbarWidget = $Root/HotbarWidget
@onready var interaction_prompt: InteractionPromptWidget = $Root/InteractionPrompt
@onready var inventory_panel: InventoryPanelWidget = $Root/InventoryPanel
@onready var tooltip_widget: LungSaTooltipWidget = $Root/TooltipWidget
@onready var confirmation_panel: ConfirmationPanelWidget = $Root/ConfirmationPanel
@onready var fortune_reveal_panel: FortuneRevealPanel = $Root/FortuneRevealPanel
@onready var waymark_travel_panel: WaymarkTravelPanelWidget = $Root/WaymarkTravelPanel
@onready var world_status_widget: WorldStatusWidget = $Root/WorldStatusWidget
@onready var creature_roster_panel: CreatureRosterPanel = $Root/CreatureRosterPanel
@onready var creature_evolution_panel: CreatureEvolutionPanel = $Root/CreatureEvolutionPanel
@onready var creature_loadout_panel: CreatureLoadoutPanel = $Root/CreatureLoadoutPanel
@onready var dialogue_panel: DialoguePanel = $Root/DialoguePanel
@onready var quest_journal_panel: QuestJournalPanel = $Root/QuestJournalPanel
@onready var shop_panel: ShopPanel = $Root/ShopPanel
@onready var crafting_panel: CraftingPanel = $Root/CraftingPanel
@onready var build_menu_panel: BuildMenuPanel = $Root/BuildMenuPanel
@onready var encyclopedia_panel: EncyclopediaPanel = $EncyclopediaPanel
@onready var toast_panel: PanelContainer = $Root/ToastPanel
@onready var toast_label: Label = $Root/ToastPanel/Margin/Label
@onready var menu_hint_panel: PanelContainer = $Root/MenuHint
@onready var menu_hint_label: Label = $Root/MenuHint/Margin/Label
@onready var modal_shade: ColorRect = $Root/ModalShade
@onready var slice_complete_panel: PanelContainer = $Root/SliceCompletePanel
@onready var slice_complete_kicker: Label = $Root/SliceCompletePanel/Margin/VBox/Kicker
@onready var slice_complete_stamp: Label = $Root/SliceCompletePanel/Margin/VBox/Stamp
@onready var slice_complete_title: Label = $Root/SliceCompletePanel/Margin/VBox/Title
@onready var slice_complete_body: Label = $Root/SliceCompletePanel/Margin/VBox/Body
@onready var slice_complete_hint: Label = $Root/SliceCompletePanel/Margin/VBox/ContinueHint
@onready var slice_restart_button: Button = $Root/SliceCompletePanel/Margin/VBox/Restart

var _player: PlayerActor = null
var _blocking_gameplay: bool = false
var _message_until_msec: int = 0
var _external_modal_sources: Dictionary = {}
var _pending_reward_reveal: Dictionary = {}

func _ready() -> void:
    layer = 10
    add_to_group(&"core_hud")
    add_to_group(&"waymark_travel_ui")
    LungSaUIStyle.apply_toast(toast_panel)
    LungSaUIStyle.apply_panel(menu_hint_panel, false)
    LungSaUIStyle.apply_muted(menu_hint_label, 11)
    LungSaUIStyle.apply_modal_panel(slice_complete_panel, LungSaUIStyle.COLOR_SUCCESS)
    LungSaUIStyle.apply_kicker(slice_complete_kicker)
    LungSaUIStyle.apply_title(slice_complete_title, 28)
    LungSaUIStyle.apply_title(slice_complete_stamp, 20)
    slice_complete_stamp.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_SUCCESS)
    slice_complete_stamp.add_theme_color_override(&"font_outline_color", Color("#08120FFF"))
    slice_complete_stamp.add_theme_constant_override(&"outline_size", 5)
    LungSaUIStyle.apply_muted(slice_complete_body, 14)
    LungSaUIStyle.apply_muted(slice_complete_hint, 12)
    LungSaUIStyle.apply_button(slice_restart_button, true)
    slice_restart_button.pressed.connect(func() -> void: slice_restart_requested.emit())

    quest_journal_panel.panel_state_changed.connect(_on_journal_state_changed)
    shop_panel.panel_state_changed.connect(_on_shop_panel_state_changed)
    shop_panel.status_message_requested.connect(show_status_message)
    crafting_panel.panel_state_changed.connect(_on_crafting_panel_state_changed)
    crafting_panel.status_message_requested.connect(show_status_message)
    build_menu_panel.panel_state_changed.connect(_on_build_menu_state_changed)
    encyclopedia_panel.panel_state_changed.connect(_on_encyclopedia_state_changed)
    inventory_panel.close_requested.connect(_on_inventory_closed)
    inventory_panel.item_slot_activated.connect(_on_inventory_item_activated)
    inventory_panel.tooltip_requested.connect(_show_tooltip)
    inventory_panel.tooltip_hidden.connect(_hide_tooltip)
    inventory_panel.slot_transfer_completed.connect(_on_slot_transfer_completed)
    inventory_panel.transfer_failed.connect(_on_transfer_failed)
    hotbar_widget.tooltip_requested.connect(_show_tooltip)
    hotbar_widget.tooltip_hidden.connect(_hide_tooltip)
    hotbar_widget.slot_transfer_completed.connect(_on_slot_transfer_completed)
    hotbar_widget.transfer_failed.connect(_on_transfer_failed)
    confirmation_panel.resolved.connect(_on_confirmation_resolved)
    confirmation_panel.dialog_state_changed.connect(_on_dialog_state_changed)
    fortune_reveal_panel.panel_state_changed.connect(_on_fortune_reveal_state_changed)
    fortune_reveal_panel.closed.connect(_on_fortune_reveal_closed)
    waymark_travel_panel.close_requested.connect(_on_waymark_panel_closed)
    waymark_travel_panel.destination_selected.connect(_on_waymark_destination_selected)
    creature_roster_panel.panel_state_changed.connect(_on_creature_panel_state_changed)
    creature_roster_panel.status_message_requested.connect(show_status_message)
    creature_roster_panel.evolution_preview_requested.connect(_on_evolution_preview_requested)
    creature_roster_panel.loadout_requested.connect(_on_loadout_requested)
    creature_evolution_panel.panel_state_changed.connect(_on_evolution_panel_state_changed)
    creature_evolution_panel.evolution_completed.connect(show_status_message)
    creature_loadout_panel.panel_state_changed.connect(_on_loadout_panel_state_changed)
    creature_loadout_panel.status_message_requested.connect(show_status_message)
    creature_loadout_panel.back_requested.connect(_on_loadout_back_requested)
    dialogue_panel.panel_state_changed.connect(_on_content_dialogue_state_changed)

    if not QuestService.quest_accepted.is_connected(_on_quest_accepted):
        QuestService.quest_accepted.connect(_on_quest_accepted)
    if not QuestService.quest_completed.is_connected(_on_quest_completed):
        QuestService.quest_completed.connect(_on_quest_completed)
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)

    _force_initial_modal_visibility()
    call_deferred("_bind_current_region_status")
    call_deferred("_add_game_shell")
    call_deferred("_build_navigation")

func _exit_tree() -> void:
    _disconnect_player_signals()
    if SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.disconnect(_on_location_changed)

func _process(_delta: float) -> void:
    if _message_until_msec > 0 and Time.get_ticks_msec() >= _message_until_msec:
        _message_until_msec = 0
        toast_panel.visible = false
    _try_show_pending_reward_reveal()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        if slice_complete_panel.visible:
            _mark_input_handled()
            return
        if fortune_reveal_panel.visible:
            fortune_reveal_panel.close_panel()
            _mark_input_handled()
            return
        if build_menu_panel.visible:
            build_menu_panel.close_panel()
            _mark_input_handled()
            return
        if crafting_panel.visible:
            crafting_panel.close_panel()
            _mark_input_handled()
            return
        if shop_panel.visible:
            shop_panel.close_panel()
            _mark_input_handled()
            return
        if quest_journal_panel.visible:
            quest_journal_panel.close_panel()
            _mark_input_handled()
            return
        if creature_loadout_panel.visible:
            creature_loadout_panel.close_panel()
            _mark_input_handled()
            return
        if creature_evolution_panel.visible:
            creature_evolution_panel.close_panel()
            _mark_input_handled()
            return
        if creature_roster_panel.visible:
            creature_roster_panel.close_panel()
            _mark_input_handled()
            return
        if waymark_travel_panel.visible:
            close_waymark_travel()
            _mark_input_handled()
            return
        if inventory_panel.visible and not confirmation_panel.visible:
            inventory_panel.close_panel()
            _mark_input_handled()
            return

    if InputMap.has_action(&"toggle_journal") and event.is_action_pressed(&"toggle_journal"):
        if not _blocking_gameplay or quest_journal_panel.visible:
            toggle_journal()
        _mark_input_handled()
        return

    if InputMap.has_action(&"toggle_creatures") and event.is_action_pressed(&"toggle_creatures"):
        if not _blocking_gameplay or creature_roster_panel.visible:
            creature_roster_panel.toggle_panel()
            _update_gameplay_block()
        _mark_input_handled()
        return

    if InputMap.has_action(&"toggle_encyclopedia") and event.is_action_pressed(&"toggle_encyclopedia"):
        toggle_encyclopedia()
        _mark_input_handled()
        return

    if InputMap.has_action(&"toggle_inventory") and event.is_action_pressed(&"toggle_inventory"):
        if not _blocking_gameplay or inventory_panel.visible:
            toggle_inventory()
        _mark_input_handled()

func toggle_encyclopedia() -> void:
    if encyclopedia_panel.visible:
        encyclopedia_panel.close_panel()
    elif not _blocking_gameplay:
        encyclopedia_panel.open_panel()
    _update_gameplay_block()

func _force_initial_modal_visibility() -> void:
    inventory_panel.visible = false
    confirmation_panel.visible = false
    fortune_reveal_panel.visible = false
    waymark_travel_panel.visible = false
    creature_roster_panel.visible = false
    creature_evolution_panel.visible = false
    creature_loadout_panel.visible = false
    dialogue_panel.visible = false
    quest_journal_panel.visible = false
    shop_panel.visible = false
    crafting_panel.visible = false
    build_menu_panel.visible = false
    encyclopedia_panel.visible = false
    tooltip_widget.visible = false
    slice_complete_panel.visible = false
    modal_shade.visible = false
    toast_panel.visible = false
    _blocking_gameplay = false

func open_build_menu(region_root: RegionRoot, player: PlayerActor) -> bool:
    if _blocking_gameplay and not build_menu_panel.visible:
        return false
    build_menu_panel.open_panel(region_root, player)
    _update_gameplay_block()
    return true

func open_crafting(station_tags: Array[StringName], title: String, inventory: InventoryComponent) -> bool:
    if _blocking_gameplay:
        return false
    var opened: bool = crafting_panel.open_station(station_tags, title, inventory)
    _update_gameplay_block()
    return opened

func _on_crafting_panel_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_build_menu_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func open_shop(shop_id: StringName, inventory: InventoryComponent, start_in_sell_mode: bool = false) -> bool:
    if _blocking_gameplay:
        return false
    var opened: bool = shop_panel.open_shop(shop_id, inventory, start_in_sell_mode)
    _update_gameplay_block()
    return opened

func _on_shop_panel_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func toggle_journal() -> void:
    if quest_journal_panel.visible:
        quest_journal_panel.close_panel()
    elif not _blocking_gameplay:
        quest_journal_panel.open_panel()
    _update_gameplay_block()

func _on_journal_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func bind_player(player: PlayerActor) -> void:
    _disconnect_player_signals()
    _player = player
    if _player == null:
        hotbar_widget.bind_hotbar(null)
        hotbar_widget.set_quick_transfer_target(null)
        interaction_prompt.bind_interactor(null)
        inventory_panel.bind_inventory(null)
        creature_roster_panel.bind_inventory(null)
        _update_gameplay_block()
        return
    hotbar_widget.bind_hotbar(_player.hotbar_component)
    hotbar_widget.set_quick_transfer_target(_player.inventory_component)
    interaction_prompt.bind_interactor(_player.interactor_component)
    inventory_panel.bind_inventory(_player.inventory_component)
    inventory_panel.set_quick_transfer_target(_player.hotbar_component)
    creature_roster_panel.bind_inventory(_player.inventory_component)
    if not _player.tool_use_component.tool_use_succeeded.is_connected(_on_tool_use_succeeded):
        _player.tool_use_component.tool_use_succeeded.connect(_on_tool_use_succeeded)
    if not _player.tool_use_component.tool_use_missed.is_connected(_on_tool_use_missed):
        _player.tool_use_component.tool_use_missed.connect(_on_tool_use_missed)
    if not _player.tool_use_component.tool_use_failed.is_connected(_on_tool_use_failed):
        _player.tool_use_component.tool_use_failed.connect(_on_tool_use_failed)
    _update_gameplay_block()

func toggle_inventory() -> void:
    if inventory_panel.visible:
        inventory_panel.close_panel()
    elif not _blocking_gameplay:
        tooltip_widget.hide_tooltip()
        inventory_panel.open_panel()
    _update_gameplay_block()

func open_inventory() -> void:
    if _blocking_gameplay and not inventory_panel.visible:
        return
    if not inventory_panel.visible:
        inventory_panel.open_panel()
    _update_gameplay_block()

func close_inventory() -> void:
    if inventory_panel.visible:
        inventory_panel.close_panel()
    _update_gameplay_block()

func open_waymark_travel(origin_waymark_id: StringName) -> void:
    if _blocking_gameplay:
        return
    tooltip_widget.hide_tooltip()
    waymark_travel_panel.open_panel(origin_waymark_id)
    _update_gameplay_block()

func close_waymark_travel() -> void:
    if waymark_travel_panel.visible:
        waymark_travel_panel.close_panel()
    _update_gameplay_block()

func show_confirmation(title: String, message: String, context_id: StringName = &"default", confirm_text: String = "Confirm", cancel_text: String = "Cancel") -> void:
    if waymark_travel_panel.visible:
        close_waymark_travel()
    tooltip_widget.hide_tooltip()
    confirmation_panel.open_confirmation(title, message, context_id, confirm_text, cancel_text)
    _update_gameplay_block()

func show_fortune_reveal(kicker: String, title: String, amount_text: String, body: String, outcome: String = "reward", seal_text: String = "REVEALED") -> void:
    if slice_complete_panel.visible:
        return
    _close_regular_modals()
    fortune_reveal_panel.open_reveal(kicker, title, amount_text, body, outcome, seal_text)
    _update_gameplay_block()

func show_status_message(message: String, seconds: float = 2.0) -> void:
    if message.strip_edges().is_empty():
        return
    toast_label.text = message
    toast_panel.visible = true
    var duration_msec: int = int(maxf(seconds, 0.4) * 1000.0)
    _message_until_msec = Time.get_ticks_msec() + duration_msec

func show_slice_completion(title: String, body: String) -> void:
    _close_regular_modals()
    slice_complete_title.text = title
    slice_complete_body.text = body
    slice_complete_panel.visible = true
    _update_gameplay_block()
    call_deferred("_focus_slice_restart")

func is_blocking_gameplay() -> bool:
    return _blocking_gameplay

func set_external_modal_blocked(source_id: StringName, blocked: bool) -> void:
    if blocked:
        _external_modal_sources[source_id] = true
    else:
        _external_modal_sources.erase(source_id)
    _update_gameplay_block()


func _close_regular_modals() -> void:
    inventory_panel.visible = false
    confirmation_panel.visible = false
    fortune_reveal_panel.visible = false
    waymark_travel_panel.visible = false
    creature_roster_panel.visible = false
    creature_evolution_panel.visible = false
    creature_loadout_panel.visible = false
    dialogue_panel.visible = false
    quest_journal_panel.visible = false
    shop_panel.visible = false
    crafting_panel.visible = false
    build_menu_panel.visible = false
    if encyclopedia_panel.visible:
        encyclopedia_panel.close_panel()

func _focus_slice_restart() -> void:
    if slice_complete_panel.visible:
        slice_restart_button.grab_focus()

func _disconnect_player_signals() -> void:
    if _player == null or not is_instance_valid(_player):
        _player = null
        return
    if _player.tool_use_component.tool_use_succeeded.is_connected(_on_tool_use_succeeded):
        _player.tool_use_component.tool_use_succeeded.disconnect(_on_tool_use_succeeded)
    if _player.tool_use_component.tool_use_missed.is_connected(_on_tool_use_missed):
        _player.tool_use_component.tool_use_missed.disconnect(_on_tool_use_missed)
    if _player.tool_use_component.tool_use_failed.is_connected(_on_tool_use_failed):
        _player.tool_use_component.tool_use_failed.disconnect(_on_tool_use_failed)

func _update_gameplay_block() -> void:
    var blocked: bool = not _external_modal_sources.is_empty() or inventory_panel.visible or confirmation_panel.visible or fortune_reveal_panel.visible or waymark_travel_panel.visible or creature_roster_panel.visible or creature_evolution_panel.visible or creature_loadout_panel.visible or dialogue_panel.visible or quest_journal_panel.visible or shop_panel.visible or crafting_panel.visible or build_menu_panel.visible or encyclopedia_panel.visible or slice_complete_panel.visible
    modal_shade.visible = blocked and not encyclopedia_panel.visible
    # Inventory is a carried-items workspace, not an isolated modal. Let pointer
    # input pass through the shade so the persistent hotbar remains a valid
    # drag/drop target while the pack is open. Other modals keep the shade
    # blocking pointer input.
    var inventory_only: bool = inventory_panel.visible and not confirmation_panel.visible and not fortune_reveal_panel.visible and not waymark_travel_panel.visible and not creature_roster_panel.visible and not creature_evolution_panel.visible and not creature_loadout_panel.visible and not dialogue_panel.visible and not quest_journal_panel.visible and not shop_panel.visible and not crafting_panel.visible and not build_menu_panel.visible and not encyclopedia_panel.visible and not slice_complete_panel.visible and _external_modal_sources.is_empty()
    modal_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE if inventory_only else Control.MOUSE_FILTER_STOP
    hotbar_widget.mouse_filter = Control.MOUSE_FILTER_STOP
    menu_hint_panel.visible = not blocked
    if blocked == _blocking_gameplay:
        if _player != null and is_instance_valid(_player):
            _player.set_input_enabled(not blocked)
        return
    _blocking_gameplay = blocked
    if _player != null and is_instance_valid(_player):
        _player.set_input_enabled(not blocked)
    gameplay_block_changed.emit(blocked)

func _on_encyclopedia_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_inventory_closed() -> void:
    _update_gameplay_block()

func _on_inventory_item_activated(slot_index: int, item_id: StringName) -> void:
    inventory_item_activated.emit(slot_index, item_id)

func _on_slot_transfer_completed(_source_container: ItemSlotContainerComponent, _source_index: int, _target_container: ItemSlotContainerComponent, _target_index: int) -> void:
    tooltip_widget.hide_tooltip()
    show_status_message("Item moved.", 1.0)

func _on_transfer_failed(message: String) -> void:
    show_status_message(message, 1.2)

func _show_tooltip(title: String, body: String, anchor_rect: Rect2) -> void:
    tooltip_widget.show_tooltip(title, body, anchor_rect)

func _hide_tooltip() -> void:
    tooltip_widget.hide_tooltip()

func _on_quest_accepted(quest_id: StringName) -> void:
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    show_status_message("Quest started  •  %s" % (definition.display_name if definition != null else String(quest_id)), 2.6)

func _on_quest_completed(quest_id: StringName) -> void:
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    if definition == null:
        show_status_message("Quest complete  •  %s" % String(quest_id), 3.0)
        return
    # The Lucky Bowl owns a custom wager reveal so it does not also open a generic reward card.
    if definition.tags.has(&"wager"):
        show_status_message("Wager settled  •  %s" % definition.display_name, 2.0)
        return
    if definition.reward_currency > 0:
        _pending_reward_reveal = {
            "kicker": "QUEST SETTLED",
            "title": definition.display_name,
            "amount": "+%d COINS" % definition.reward_currency,
            "body": "Payment received. The Ledger does not care whether the money came from farming, heroics, or a creature-shaped paperwork emergency.",
            "outcome": "reward",
            "seal": "PAID OUT",
        }
        call_deferred("_try_show_pending_reward_reveal")
        return
    show_status_message("Quest complete  •  %s" % definition.display_name, 3.0)

func _on_content_dialogue_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_dialog_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()
    call_deferred("_try_show_pending_reward_reveal")

func _on_fortune_reveal_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_fortune_reveal_closed() -> void:
    _update_gameplay_block()
    call_deferred("_try_show_pending_reward_reveal")

func _on_confirmation_resolved(context_id: StringName, accepted: bool) -> void:
    confirmation_resolved.emit(context_id, accepted)
    _update_gameplay_block()

func _on_waymark_panel_closed() -> void:
    _update_gameplay_block()

func _on_creature_panel_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_evolution_panel_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_loadout_panel_state_changed(_is_open: bool) -> void:
    _update_gameplay_block()

func _on_loadout_requested(instance_id: String) -> void:
    if creature_roster_panel.visible:
        creature_roster_panel.close_panel()
    creature_loadout_panel.open_for_creature(instance_id)
    _update_gameplay_block()

func _on_loadout_back_requested() -> void:
    creature_roster_panel.open_panel()
    _update_gameplay_block()

func _on_evolution_preview_requested(instance_id: String) -> void:
    if creature_roster_panel.visible:
        creature_roster_panel.close_panel()
    creature_evolution_panel.open_for_creature(instance_id)
    _update_gameplay_block()

func _on_waymark_destination_selected(waymark_id: StringName) -> void:
    waymark_destination_selected.emit(waymark_id)

func _on_tool_use_succeeded(tool: ToolDefinition, target: ToolTargetComponent) -> void:
    show_status_message("%s  •  %s" % [tool.display_name, target.get_parent().name], 1.3)

func _on_tool_use_missed(tool: ToolDefinition) -> void:
    show_status_message("No %s target in reach." % tool.display_name, 1.5)

func _on_tool_use_failed(reason: StringName) -> void:
    if reason == &"cooldown":
        return
    show_status_message("Cannot use tool  •  %s" % String(reason).replace("_", " "), 1.6)

func _on_location_changed(_region_id: StringName, _zone_id: StringName, _spawn_id: StringName) -> void:
    call_deferred("_bind_current_region_status")

func _bind_current_region_status() -> void:
    var region_root: RegionRoot = SceneRouter.get_current_region_root()
    if region_root == null:
        world_status_widget.bind_ambient_controller(null)
        return
    var ambient: RegionAmbientController = region_root.get_local_system(&"AmbientController") as RegionAmbientController
    world_status_widget.bind_ambient_controller(ambient)

func _try_show_pending_reward_reveal() -> void:
    if _pending_reward_reveal.is_empty() or fortune_reveal_panel.visible or slice_complete_panel.visible:
        return
    if confirmation_panel.visible or dialogue_panel.visible or inventory_panel.visible or waymark_travel_panel.visible or creature_roster_panel.visible or creature_evolution_panel.visible or creature_loadout_panel.visible or quest_journal_panel.visible or shop_panel.visible or crafting_panel.visible or build_menu_panel.visible or encyclopedia_panel.visible:
        return
    var reveal: Dictionary = _pending_reward_reveal.duplicate(true)
    _pending_reward_reveal.clear()
    show_fortune_reveal(
        str(reveal.get("kicker", "REWARD")),
        str(reveal.get("title", "Reward")),
        str(reveal.get("amount", "")),
        str(reveal.get("body", "")),
        str(reveal.get("outcome", "reward")),
        str(reveal.get("seal", "REVEALED"))
    )

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

func _add_game_shell() -> void:
    var shell: CanvasLayer = CanvasLayer.new()
    shell.set_script(preload("res://presentation/slice_menu.gd"))
    add_child(shell)

func _build_navigation() -> void:
    menu_hint_label.hide()
    menu_hint_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    $Root/MenuHint/Margin.add_child(row)
    var titles: Array[String] = ["Pack  I","Crew  C","Journal  J","Notes  K","Build  B"]
    var actions: Array[Callable] = [toggle_inventory, _toggle_crew_button, toggle_journal, toggle_encyclopedia, _toggle_build_button]
    for i: int in range(titles.size()):
        var button: Button = Button.new()
        button.text = titles[i]
        button.custom_minimum_size = Vector2(72,34)
        LungSaUIStyle.apply_button(button)
        button.add_theme_font_size_override("font_size",12)
        button.pressed.connect(actions[i])
        row.add_child(button)

func _toggle_crew_button() -> void:
    if _blocking_gameplay: return
    creature_roster_panel.toggle_panel()
    _update_gameplay_block()

func _toggle_build_button() -> void:
    if _blocking_gameplay and not build_menu_panel.visible:
        return
    var region_root: RegionRoot = SceneRouter.get_current_region_root()
    if region_root == null or _player == null:
        return
    if build_menu_panel.visible:
        build_menu_panel.close_panel()
    else:
        build_menu_panel.open_panel(region_root, _player)
    _update_gameplay_block()
