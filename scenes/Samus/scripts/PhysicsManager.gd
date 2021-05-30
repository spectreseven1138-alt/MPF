extends Node

onready var Samus: KinematicBody2D = get_parent()

const GRAVITY = 20*60
const FALL_SPEED_CAP = 325
const UP_DIRECTION = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_DISTANCE = 15.0
const SNAP_VECTOR = SNAP_DIRECTION * SNAP_DISTANCE

var vel: Vector2 = Vector2.ZERO
var apply_gravity: bool = true
var apply_velocity: bool = true
var disable_floor_snap: bool = false
var on_slope: bool = false

# Keeping this around for the memories
#var time = -1

func _physics_process(delta: float):
	
	if Samus.is_on_ceiling() or Samus.is_on_wall():
		Samus.boosting = false
	
	if get_tree().paused:
		Samus.move_and_slide_with_snap(Vector2.ZERO, Vector2.ZERO)
		return
	
	if apply_gravity:
		vel.y = min(vel.y + GRAVITY*delta, FALL_SPEED_CAP)
	
	var slope_angle = Samus.get_floor_normal().dot(Vector2.UP)
	on_slope = slope_angle != 0 and slope_angle != 1
	
	if apply_velocity:
		var result_velocity = Samus.move_and_slide_with_snap(vel, SNAP_VECTOR if not disable_floor_snap else Vector2.ZERO, UP_DIRECTION, true)
		
		if slope_angle:
			vel.y = result_velocity.y
		else:
			vel = result_velocity
	vOverlay.SET("Physics.vel", vel)
	
	disable_floor_snap = false

func can_walk(direction: int):
	var collision = Samus.move_and_collide(Vector2(1*direction, 0), true, true, true)
	if not collision:
		return true
	else:
		var slope_angle = abs(collision.normal.dot(Vector2.UP))
		print(slope_angle)
		return slope_angle < 0.785398 and slope_angle != 0

func decelerate_x(amount: float):
	if vel.x > 0:
		vel.x = max(vel.x - amount, 0)
	elif vel.x < 0:
		vel.x = min(vel.x + amount, 0)
		
func accelerate_x(amount: float, limit: float, direction: int):
	
	if direction == Enums.dir.LEFT:
		vel.x = max(vel.x - amount, -limit)
	elif direction == Enums.dir.RIGHT:
		vel.x = min(vel.x + amount, limit)
	else:
		return -1

func accelerate_y(amount: float, limit: float, direction: int):
	if direction == Enums.dir.UP:
		vel.y = max(vel.y - amount, -limit)
	elif direction == Enums.dir.DOWN:
		vel.y = min(vel.y + amount, limit)
	else:
		return -1
	disable_floor_snap = true
