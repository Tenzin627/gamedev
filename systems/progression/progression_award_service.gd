extends RefCounted
class_name ProgressionAwardService

static func award_farming(amount: int = 1) -> int:
    return PlayerProgressionService.add_points(PlayerProgressionService.TRACK_FARMER, amount)

static func award_taming(amount: int = 1) -> int:
    return PlayerProgressionService.add_points(PlayerProgressionService.TRACK_TAMER, amount)

static func award_exploration(amount: int = 1) -> int:
    return PlayerProgressionService.add_points(PlayerProgressionService.TRACK_EXPLORER, amount)
