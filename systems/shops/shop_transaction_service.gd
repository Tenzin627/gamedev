extends RefCounted
class_name ShopTransactionService

static func get_buy_price(shop: ShopDefinition, entry: ShopStockEntry) -> int:
    if shop == null or entry == null:
        return 0
    var item: ItemDefinition = ContentDB.get_definition(entry.item_id) as ItemDefinition
    if item == null:
        return 0
    return maxi(int(round(float(item.buy_value) * shop.global_buy_multiplier * entry.buy_price_multiplier * EconomyBalanceService.progression_buy_multiplier())), 0)

static func get_sell_price(shop: ShopDefinition, item_id: StringName) -> int:
    if shop == null:
        return 0
    var item: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
    if item == null:
        return 0
    return maxi(int(round(float(item.sell_value) * shop.global_sell_multiplier)), 0)

static func buy(shop: ShopDefinition, stock_index: int, inventory: InventoryComponent) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "", "currency": int(GameSession.get_value(&"currency", 0))}
    if shop == null or inventory == null or stock_index < 0 or stock_index >= shop.stock.size():
        result["message"] = "Trade is unavailable."
        return result
    var entry: ShopStockEntry = shop.stock[stock_index]
    if entry == null or not _conditions_met(entry.required_conditions):
        result["message"] = "That item is not available yet."
        return result
    var purchased: int = maxi(entry.quantity_per_purchase, 1)
    var remaining_stock: int = get_remaining_stock(shop, stock_index)
    if entry.stock_limit >= 0 and remaining_stock < purchased:
        result["message"] = "Sold out."
        return result
    if not CarriedInventoryService.can_add_item(inventory, entry.item_id, purchased):
        result["message"] = "Inventory is full."
        return result
    var price: int = get_buy_price(shop, entry)
    var currency: int = int(GameSession.get_value(&"currency", 0))
    if currency < price:
        result["message"] = "Not enough currency."
        return result
    GameSession.set_value(&"currency", currency - price)
    var leftover: int = CarriedInventoryService.add_item(inventory, entry.item_id, purchased)
    if leftover > 0:
        CarriedInventoryService.remove_item(inventory, entry.item_id, purchased - leftover)
        GameSession.set_value(&"currency", currency)
        result["message"] = "Inventory changed before the trade completed."
        return result
    if entry.stock_limit >= 0:
        _set_purchased_count(shop.content_id, stock_index, _get_purchased_count(shop.content_id, stock_index) + purchased)
    result["success"] = true
    result["currency"] = currency - price
    var item: ItemDefinition = ContentDB.get_definition(entry.item_id) as ItemDefinition
    result["message"] = "Bought %s ×%d for %d." % [item.display_name if item != null else String(entry.item_id), purchased, price]
    return result

static func sell(shop: ShopDefinition, item_id: StringName, inventory: InventoryComponent, amount: int = 1) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "", "currency": int(GameSession.get_value(&"currency", 0))}
    if shop == null or inventory == null or not shop.allow_selling or amount <= 0:
        result["message"] = "Selling is unavailable."
        return result
    var item: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
    var owned: int = CarriedInventoryService.get_total_quantity(inventory, item_id)
    var unit_price: int = EconomyBalanceService.adjusted_sell_price(get_sell_price(shop, item_id), owned)
    if item == null or unit_price <= 0:
        result["message"] = "This shop will not buy that item."
        return result
    if not CarriedInventoryService.has_item(inventory, item_id, amount):
        result["message"] = "You do not have enough to sell."
        return result
    var remaining: int = CarriedInventoryService.remove_item(inventory, item_id, amount)
    if remaining > 0:
        result["message"] = "The sale could not be completed."
        return result
    var earned: int = unit_price * amount
    var currency: int = int(GameSession.get_value(&"currency", 0)) + earned
    GameSession.set_value(&"currency", currency)
    result["success"] = true
    result["currency"] = currency
    result["message"] = "Sold %s ×%d for %d." % [item.display_name, amount, earned]
    return result

static func get_remaining_stock(shop: ShopDefinition, stock_index: int) -> int:
    if shop == null or stock_index < 0 or stock_index >= shop.stock.size():
        return 0
    var entry: ShopStockEntry = shop.stock[stock_index]
    if entry == null or entry.stock_limit < 0:
        return -1
    return maxi(entry.stock_limit - _get_purchased_count(shop.content_id, stock_index), 0)

static func _conditions_met(conditions: Array[ContentCondition]) -> bool:
    for condition: ContentCondition in conditions:
        if condition != null and not ContentConditionEvaluator.evaluate(condition):
            return false
    return true

static func _get_purchased_count(shop_id: StringName, stock_index: int) -> int:
    var store: Dictionary = Dictionary(GameSession.get_value(&"shop_runtime", {}))
    var shop_state: Dictionary = Dictionary(store.get(String(shop_id), {}))
    return int(shop_state.get(str(stock_index), 0))

static func _set_purchased_count(shop_id: StringName, stock_index: int, value: int) -> void:
    var store: Dictionary = Dictionary(GameSession.get_value(&"shop_runtime", {})).duplicate(true)
    var shop_state: Dictionary = Dictionary(store.get(String(shop_id), {})).duplicate(true)
    shop_state[str(stock_index)] = maxi(value, 0)
    store[String(shop_id)] = shop_state
    GameSession.set_value(&"shop_runtime", store)
