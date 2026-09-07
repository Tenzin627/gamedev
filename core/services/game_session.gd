extends Node

signal session_started(profile_id: String)
signal session_imported
signal session_state_changed(key: StringName, value: Variant)
signal creature_collection_changed
signal party_changed

const PARTY_SIZE: int = 3

var profile_id: String = "default"
var session_state: Dictionary = {}
var creature_instances: Array[Dictionary] = []
var party_instance_ids: Array[String] = []
var _fresh_start_pending: bool = true

func _ready() -> void:
    if profile_id.is_empty():
        profile_id = "default"
    if session_state.is_empty():
        session_state = _make_default_session_state()
        _fresh_start_pending = true
    else:
        _ensure_default_keys()
        _fresh_start_pending = false

func start_new_session(new_profile_id: String = "default") -> void:
    profile_id = new_profile_id if not new_profile_id.is_empty() else "default"
    session_state = _make_default_session_state()
    creature_instances.clear()
    party_instance_ids.clear()
    _fresh_start_pending = true
    session_started.emit(profile_id)
    creature_collection_changed.emit()
    party_changed.emit()

func is_fresh_start_pending() -> bool:
    return _fresh_start_pending

func mark_fresh_start_applied() -> void:
    _fresh_start_pending = false

func set_value(key: StringName, value: Variant) -> void:
    session_state[String(key)] = value
    session_state_changed.emit(key, value)

func get_value(key: StringName, default_value: Variant = null) -> Variant:
    return session_state.get(String(key), default_value)

func set_region_runtime_state(zone_id: StringName, state: Dictionary) -> void:
    if zone_id == &"":
        return
    var runtime_store: Dictionary = _get_region_runtime_store()
    runtime_store[String(zone_id)] = state.duplicate(true)
    session_state["region_runtime"] = runtime_store
    session_state_changed.emit(&"region_runtime", runtime_store.duplicate(true))

func get_region_runtime_state(zone_id: StringName) -> Dictionary:
    if zone_id == &"":
        return {}
    var runtime_store: Dictionary = _get_region_runtime_store()
    var stored: Variant = runtime_store.get(String(zone_id), {})
    if stored is Dictionary:
        return Dictionary(stored).duplicate(true)
    return {}

func has_region_runtime_state(zone_id: StringName) -> bool:
    if zone_id == &"":
        return false
    return _get_region_runtime_store().has(String(zone_id))

func erase_region_runtime_state(zone_id: StringName) -> void:
    if zone_id == &"":
        return
    var runtime_store: Dictionary = _get_region_runtime_store()
    if not runtime_store.has(String(zone_id)):
        return
    runtime_store.erase(String(zone_id))
    session_state["region_runtime"] = runtime_store
    session_state_changed.emit(&"region_runtime", runtime_store.duplicate(true))

func clear_region_runtime_states() -> void:
    session_state["region_runtime"] = {}
    session_state_changed.emit(&"region_runtime", {})

func export_state() -> Dictionary:
    return {
        "profile_id": profile_id,
        "session_state": session_state.duplicate(true),
        "creature_instances": creature_instances.duplicate(true),
        "party_instance_ids": party_instance_ids.duplicate(),
    }

func import_state(data: Dictionary) -> void:
    profile_id = str(data.get("profile_id", "default"))
    session_state = Dictionary(data.get("session_state", {})).duplicate(true)
    creature_instances.clear()

    var creature_variant: Variant = data.get("creature_instances", [])
    if creature_variant is Array:
        for entry_variant: Variant in Array(creature_variant):
            if not entry_variant is Dictionary:
                continue
            var normalized: CreatureInstanceData = CreatureInstanceData.from_dict(Dictionary(entry_variant))
            if normalized.instance_id.is_empty() or normalized.species_id == &"":
                continue
            creature_instances.append(normalized.to_dict())

    party_instance_ids.clear()
    var valid_instance_ids: Dictionary = {}
    for creature_entry: Dictionary in creature_instances:
        var creature_id: String = str(creature_entry.get("instance_id", ""))
        if not creature_id.is_empty():
            valid_instance_ids[creature_id] = true

    var party_variant: Variant = data.get("party_instance_ids", [])
    if party_variant is Array:
        for instance_variant: Variant in Array(party_variant):
            var instance_id: String = str(instance_variant)
            if instance_id.is_empty() or not valid_instance_ids.has(instance_id) or party_instance_ids.has(instance_id):
                continue
            party_instance_ids.append(instance_id)
            if party_instance_ids.size() >= PARTY_SIZE:
                break

    _ensure_default_keys()
    _fresh_start_pending = false
    session_imported.emit()
    creature_collection_changed.emit()
    party_changed.emit()

func notify_creature_collection_changed() -> void:
    creature_collection_changed.emit()

func notify_party_changed() -> void:
    party_changed.emit()

func _get_region_runtime_store() -> Dictionary:
    var stored: Variant = session_state.get("region_runtime", {})
    if stored is Dictionary:
        return Dictionary(stored).duplicate(true)
    return {}

func _ensure_default_keys() -> void:
    _migrate_legacy_keys()
    var defaults: Dictionary = _make_default_session_state()
    for key: Variant in defaults.keys():
        if not session_state.has(key):
            session_state[key] = defaults[key]

func _migrate_legacy_keys() -> void:
    var legacy_recipes: Variant = session_state.get("recipe_unlocks", [])
    var discovered: Array = Array(session_state.get("discovered_recipes", [])).duplicate()
    if legacy_recipes is Array:
        for recipe_id: Variant in Array(legacy_recipes):
            var text_id: String = str(recipe_id)
            if not text_id.is_empty() and not discovered.has(text_id):
                discovered.append(text_id)
    session_state["discovered_recipes"] = discovered
    session_state.erase("recipe_unlocks")

func _make_default_session_state() -> Dictionary:
    return {
        "currency": 0,
        "inventory_slots": {},
        "hotbar": {},
        "region_runtime": {},
        "pending_battle_return": {},
        "quest_runtime": {},
        "shop_runtime": {},
        "content_talked_npcs": {},
        "content_events_completed": [],
        "discovered_recipes": [],
        "pending_item_rewards": [],
        "active_waymarks": [],
        "exploration_discoveries": [],
        "player_progression": {"tracks": {}, "claimed_milestones": []},
        "encyclopedia_seen_creatures": [],
        "encyclopedia_owned_creatures": [],
        "encyclopedia_evolved_creatures": [],
        "world_time": {
            "total_game_minutes": 480,
            "running": true,
            "game_minutes_per_real_second": 2.0,
        },
    }
