extends RefCounted
class_name IsoGrid

const TILE_W := 64.0
const TILE_H := 32.0

static func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) - float(cell.y)) * TILE_W * 0.5,
		(float(cell.x) + float(cell.y)) * TILE_H * 0.5
	)

static func world_to_grid(pos: Vector2) -> Vector2i:
	var gx := (pos.x / (TILE_W * 0.5) + pos.y / (TILE_H * 0.5)) * 0.5
	var gy := (pos.y / (TILE_H * 0.5) - pos.x / (TILE_W * 0.5)) * 0.5
	return Vector2i(roundi(gx), roundi(gy))

static func diamond(cell: Vector2i) -> PackedVector2Array:
	var center := grid_to_world(cell)
	return PackedVector2Array([
		center + Vector2(0,-TILE_H*0.5),
		center + Vector2(TILE_W*0.5,0),
		center + Vector2(0,TILE_H*0.5),
		center + Vector2(-TILE_W*0.5,0),
		center + Vector2(0,-TILE_H*0.5)
	])

static func footprint_cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(size.x):
		for y in range(size.y):
			out.append(origin + Vector2i(x,y))
	return out