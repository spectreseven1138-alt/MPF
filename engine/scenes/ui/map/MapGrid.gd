extends Control

onready var Tiles: Node2D = $Center/Tiles
onready var Background: TextureRect = $Background
onready var tween: Tween = $Tween
onready var backgroundOffsetTween: Tween = $BackgroundOffsetTween

#onready var minimap_size: Vector2 = self.rect_size
#var default_scale: Vector2 = rect_scale
onready var default_position: Vector2 = rect_position

var focus_position = Vector2.ZERO setget set_focus_position

var minimap_scale: Vector2 = Vector2.ONE

var background_offset: Vector2 = Vector2.ZERO setget set_background_offset
const default_background_size: Vector2 = Vector2(40, 24)
var background_size: Vector2 = default_background_size

func _ready():
	backgroundOffsetTween.connect("tween_step", self, "background_offset_tween_step")

func fade(fade_in: bool, duration: float):
	tween.interpolate_property(self, "modulate:a", int(!fade_in), int(fade_in), duration)
	tween.start()
	yield(tween, "tween_completed")

func set_background_offset(value: Vector2):
	if value == background_offset:
		return
	background_offset = value.posmod(8)
	Background.rect_position = Vector2(-8, -8) + background_offset

var map_offset_offset = Vector2.ZERO
func update_minimap():
	rect_scale = minimap_scale
	rect_pivot_offset = rect_size/2
	rect_min_size = background_size# / rect_scale
	rect_size = rect_min_size
	Background.rect_size = background_size + Vector2(8, 8)
	Background.rect_min_size = background_size + Vector2(8, 8)
#	Background.rect_pivot_offset = Background.rect_size / 2
	
#	Background.rect_pivot_offset = Background.rect_size/2
#	$CenterContainer.rect_min_size = rect_size
#	$CenterContainer.rect_size = rect_size
	set_background_offset(Tiles.position + map_offset_offset)

func reset_minimap_properties():
#	rect_size = minimap_size
#	rect_scale = _scale
	minimap_scale = Vector2.ONE
	rect_position = default_position
	background_size = default_background_size
	map_offset_offset = Vector2.ZERO
	visible = true

#	modulate = Color.white
func set_focus_position(position: Vector2, instant: bool = false):
	focus_position = position
	if not backgroundOffsetTween.is_inside_tree():
		return
	backgroundOffsetTween.interpolate_property(Tiles, "position", Tiles.position, -position, 0.0 if instant else 0.1, Tween.TRANS_LINEAR)
	backgroundOffsetTween.start()

func background_offset_tween_step(object: Object, key: NodePath, elapsed: float, value: Object):
	update_minimap()

func show_all_tiles(tiles: Array = Tiles.get_children(), instant: bool = false):
	
	# TODO | Set scale
	
	var max_pos: = Vector2.ZERO
	var min_pos: = Vector2.ZERO
	
	for tile in tiles:
		for axis in ["x", "y"]:
			max_pos[axis] = max(max_pos[axis], tile.grid_position[axis])
			min_pos[axis] = min(min_pos[axis], tile.grid_position[axis])
	
	var center: Vector2 = max_pos - min_pos
	set_focus_position(center, instant)