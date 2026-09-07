extends Node

const OPENING_SHOWN_KEY: StringName = &"phase7.opening_shown"

func _ready() -> void:
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)
    if not DebtService.installment_paid.is_connected(_on_installment_paid):
        DebtService.installment_paid.connect(_on_installment_paid)
    if not GameSession.session_state_changed.is_connected(_on_session_state_changed):
        GameSession.session_state_changed.connect(_on_session_state_changed)
    call_deferred("_bind_hud")
    call_deferred("_maybe_show_opening")

func _on_location_changed(_region_id: StringName, _zone_id: StringName, _spawn_id: StringName) -> void:
    call_deferred("_bind_hud")
    call_deferred("_maybe_show_opening")

func _on_session_state_changed(key: StringName, _value: Variant) -> void:
    if key == &"slice.welcomed":
        call_deferred("_maybe_show_opening")

func _bind_hud() -> void:
    var hud: CoreHUD = _get_hud()
    if hud != null and not hud.slice_restart_requested.is_connected(_on_restart_requested):
        hud.slice_restart_requested.connect(_on_restart_requested)

func _maybe_show_opening() -> void:
    if bool(GameSession.get_value(OPENING_SHOWN_KEY, false)):
        return
    if not bool(GameSession.get_value(&"slice.welcomed", false)):
        return
    var profile: GameProfileDefinition = ContentDB.get_active_profile()
    if profile == null or SceneRouter.current_zone_id != profile.starter_zone_id:
        return
    var hud: CoreHUD = _get_hud()
    if hud == null or hud.is_blocking_gameplay():
        return
    GameSession.set_value(OPENING_SHOWN_KEY, true)
    DebtService.initialize_if_needed()
    hud.show_fortune_reveal(
        "THE LEDGER  •  INHERITANCE DRAW",
        "YOU WON THE FARM",
        "+1 FARM  •  +100,000 DEBT",
        "The wager was technically successful. The paperwork was not.\n\nCOLLECTION 01: 500 coins.\nLedger Clerk: Basin Village.",
        "debt",
        "CLAIM ACCEPTED"
    )

func _on_installment_paid(amount: int, remaining_total: int) -> void:
    await get_tree().process_frame
    var hud: CoreHUD = _get_hud()
    if hud == null:
        return
    hud.show_slice_completion(
        "FIRST COLLECTION",
        "%d COINS SURRENDERED\n\nOutstanding balance: %d\n\nYou reduced one terrible decision by 0.5%%. The Ledger has many more pages, and the road beyond the Basin is waiting." % [amount, remaining_total]
    )

func _on_restart_requested() -> void:
    DemoBootstrap.restart_demo()

func _get_hud() -> CoreHUD:
    var root: RegionRoot = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    return root.get_node_or_null(^"CoreHUD") as CoreHUD if root != null else null
