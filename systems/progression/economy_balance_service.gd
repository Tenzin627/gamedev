extends RefCounted
class_name EconomyBalanceService

const BASE_SELL_RATE: float = 1.0
const BULK_SOFT_CAP: int = 20
const BULK_FLOOR: float = 0.55

static func adjusted_sell_price(base_price: int, owned_quantity: int) -> int:
    if base_price <= 0:
        return 0
    var excess: int = maxi(owned_quantity - BULK_SOFT_CAP, 0)
    var multiplier: float = maxf(BASE_SELL_RATE - float(excess) * 0.015, BULK_FLOOR)
    return maxi(int(round(float(base_price) * multiplier)), 1)

static func progression_buy_multiplier() -> float:
    var explorer_rank: int = PlayerProgressionService.get_rank(PlayerProgressionService.TRACK_EXPLORER)
    return maxf(1.0 - float(explorer_rank) * 0.025, 0.90)
