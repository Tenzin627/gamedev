extends RefCounted
class_name WorldGrid

const TILE_SIZE_PX: int = 64
const HALF_TILE_PX: float = 32.0

static func cell_to_local(cell: Vector2i) -> Vector2:
    return Vector2(float(cell.x * TILE_SIZE_PX), float(cell.y * TILE_SIZE_PX))

static func cell_to_center(cell: Vector2i) -> Vector2:
    return cell_to_local(cell) + Vector2(HALF_TILE_PX, HALF_TILE_PX)

static func local_to_cell(local_position: Vector2) -> Vector2i:
    return Vector2i(
        floori(local_position.x / float(TILE_SIZE_PX)),
        floori(local_position.y / float(TILE_SIZE_PX))
    )

static func snap_local_to_grid(local_position: Vector2) -> Vector2:
    return cell_to_local(local_to_cell(local_position))
