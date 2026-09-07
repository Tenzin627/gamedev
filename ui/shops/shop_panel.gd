extends PanelContainer
class_name ShopPanel

signal panel_state_changed(is_open: bool)
signal status_message_requested(message: String)

@onready var title_label: Label = $Margin/Layout/Header/Title
@onready var currency_label: Label = $Margin/Layout/Header/Currency
@onready var buy_button: Button = $Margin/Layout/Tabs/BuyButton
@onready var sell_button: Button = $Margin/Layout/Tabs/SellButton
@onready var list_box: VBoxContainer = $Margin/Layout/Scroll/List
@onready var help_label: Label = $Margin/Layout/Help
@onready var close_button: Button = $Margin/Layout/CloseButton

var _shop: ShopDefinition = null
var _inventory: InventoryComponent = null
var _sell_mode: bool = false

func _ready() -> void:
    add_to_group(&"shop_panel")
    visible = false
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 27)
    LungSaUIStyle.apply_muted(currency_label, 13)
    LungSaUIStyle.apply_muted(help_label, 11)
    LungSaUIStyle.apply_button(close_button, false)
    buy_button.pressed.connect(_show_buy)
    sell_button.pressed.connect(_show_sell)
    close_button.pressed.connect(close_panel)

func open_shop(shop_id: StringName, inventory: InventoryComponent, start_in_sell_mode: bool = false) -> bool:
    _shop = ContentDB.get_definition(shop_id) as ShopDefinition
    _inventory = inventory
    if _shop == null or _inventory == null:
        return false
    _sell_mode = start_in_sell_mode and _shop.allow_selling
    visible = true
    _refresh()
    panel_state_changed.emit(true)
    return true

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func _show_buy() -> void:
    _sell_mode = false
    _refresh()

func _show_sell() -> void:
    _sell_mode = true
    _refresh()

func _refresh() -> void:
    for child: Node in list_box.get_children():
        child.queue_free()
    if _shop == null:
        return
    title_label.text = _shop.display_name
    currency_label.text = "%d  currency" % int(GameSession.get_value(&"currency", 0))
    buy_button.disabled = false
    sell_button.disabled = not _shop.allow_selling
    LungSaUIStyle.apply_tab_button(buy_button, not _sell_mode)
    LungSaUIStyle.apply_tab_button(sell_button, _sell_mode)
    help_label.text = "Buy only what the short demo needs." if not _sell_mode else "Sell carried goods quickly. Tools and seeds are protected by zero sell value."
    if _sell_mode:
        _populate_sell()
    else:
        _populate_buy()
    var first: Control = _first_focusable()
    if first != null:
        first.grab_focus()

func _populate_buy() -> void:
    for index: int in range(_shop.stock.size()):
        var entry: ShopStockEntry = _shop.stock[index]
        if entry == null:
            continue
        var item: ItemDefinition = ContentDB.get_definition(entry.item_id) as ItemDefinition
        if item == null:
            continue
        var remaining: int = ShopTransactionService.get_remaining_stock(_shop, index)
        var price: int = ShopTransactionService.get_buy_price(_shop, entry)
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0.0, 50.0)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        var stock_text: String = "∞" if remaining < 0 else str(remaining)
        button.text = "%s  ×%d     %d currency     Stock %s" % [item.display_name, entry.quantity_per_purchase, price, stock_text]
        button.disabled = remaining == 0
        LungSaUIStyle.apply_button(button, false)
        button.pressed.connect(_buy.bind(index))
        list_box.add_child(button)

func _populate_sell() -> void:
    var added_ids: Dictionary = {}
    for item_id: StringName in CarriedInventoryService.get_item_ids(_inventory):
        if item_id == &"" or added_ids.has(item_id):
            continue
        added_ids[item_id] = true
        var item: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
        if item == null:
            continue
        var quantity: int = CarriedInventoryService.get_total_quantity(_inventory, item_id)
        var base_price: int = ShopTransactionService.get_sell_price(_shop, item_id)
        var unit_price: int = EconomyBalanceService.adjusted_sell_price(base_price, quantity)
        if unit_price <= 0 or quantity <= 0:
            continue
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0.0, 50.0)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.text = "%s     ×%d     Sell all for %d" % [item.display_name, quantity, unit_price * quantity]
        button.tooltip_text = "Sell the whole carried stack at %d each." % unit_price
        LungSaUIStyle.apply_button(button, false)
        button.pressed.connect(_sell.bind(item_id, quantity))
        list_box.add_child(button)

func _buy(stock_index: int) -> void:
    var result: Dictionary = ShopTransactionService.buy(_shop, stock_index, _inventory)
    status_message_requested.emit(str(result.get("message", "")))
    _refresh()

func _sell(item_id: StringName, amount: int = 1) -> void:
    var result: Dictionary = ShopTransactionService.sell(_shop, item_id, _inventory, amount)
    status_message_requested.emit(str(result.get("message", "")))
    _refresh()

func _first_focusable() -> Control:
    for child: Node in list_box.get_children():
        if child is Control and not (child as Control).is_visible_in_tree():
            continue
        if child is Button and not (child as Button).disabled:
            return child as Control
    return close_button
