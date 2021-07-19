extends Node

const id: String = "shinespark"

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

var animations: Dictionary
var physics_data: Dictionary

const damage_type: int = Enums.DamageType.SPEEDBOOSTER
var damage_values: Dictionary = Data.data["damage_values"]["samus"]["weapons"]["speedbooster"]
var damage_amount: float = damage_values["damage"]

var ShinesparkUseWindow: Timer = Global.timer([self, "discharge_shinespark", []])
var shinespark_hold_time: float = 3.0

var ShinesparkStoreWindow: Timer = Global.timer()
var shinespark_store_window: float = 0.2
var SpeedboostAnimationPlayer: AnimationPlayer

# Well this is nostalgic (18 jul)
#var SpeedboosterRaycasts: Array
#var SpeedboosterArea: Area2D

var direction: Vector2
var velocity: Vector2
var moving: bool = false
var ballspark: bool = false
var sprite

# Called during Samus's readying period
func _init(_samus: Node2D):
	Samus = _samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	
	SpeedboostAnimationPlayer = Animator.get_node("SpeedboostAnimationPlayer")
	
	animations = Animator.load_from_json(self.id)
	physics_data = Physics.data["shinespark"]


# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	
	Physics.apply_gravity = false
	Physics.vel = Vector2.ZERO
	
	discharge_shinespark()
	Physics.disable_floor_snap = true
	if Samus.is_on_floor():
		Physics.vel.y = -50
	
	Samus.boosting = true
	
	ballspark = data["ballspark"]
	if not ballspark:
		yield(animations["start"].play(), "completed")
		Physics.vel.y = 0
	else:
		yield(Global.wait(0.05), "completed")
		Physics.vel.y = 0
		yield(Global.wait(0.15), "completed")
	
	direction = Shortcut.get_pad_vector("pressed")
	if direction == Vector2.ZERO:
		direction = Vector2(0, -1)
	velocity = direction.normalized() * physics_data["speed"]
	Physics.vel = velocity
	
	if direction.x != 0:
		Samus.facing = Enums.dir.LEFT if direction.x == -1 else Enums.dir.RIGHT
	if not ballspark:
		animations["horiz" if direction.x != 0 else "vert"].play()
		if direction == Vector2(0, 1):
			sprite = Animator.current[false].sprites[Samus.facing]
			sprite.flip_v = true
	else:
		animations["roll"].play()
	
	moving = true

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	
	if sprite != null:
		sprite.flip_v = false
	moving = false
	Physics.apply_gravity = true
	
	Samus.change_state(new_state_key, data)
	
# Called every frame while this state is active
func process(_delta):

#	if animation_key:
#		Samus.set_collider(animations[animation_key])
	
	if not moving:
		return
	
	Physics.vel = velocity
#	Samus.boosting = true
	vOverlay.SET("Slope", Physics.on_slope)
	if Physics.on_slope and direction.x != 0:
		moving = false
		print("BNDAGBHJDGB")
		Physics.apply_gravity = true
		Animator.resume()
		if ballspark:
			ballspark = false
			change_state("morphball", {"options": ["animate"]})
		else:
			change_state("run", {"boost": true})
		return
	elif Input.is_action_just_pressed("airboost"):
		change_state("airboost")
		return
	
	var stop_shinespark = false
	if direction.y == 0:
		stop_shinespark = Samus.is_on_wall()
	elif direction.x == 0:
		stop_shinespark = Samus.is_on_ceiling() if direction.y == 1 else Samus.is_on_floor()
	else:
		if direction.y == 1:
			stop_shinespark = Samus.is_on_ceiling() or Samus.is_on_wall()
		else:
			stop_shinespark = Samus.is_on_floor() or Samus.is_on_wall()
	
	if stop_shinespark:
		
		Physics.vel = Vector2.ZERO
		Samus.boosting = false
		moving = false
		
#		Global.shake(Samus.camera, Vector2(0, 0), 7, 0.25)
		Loader.current_room.earthquake(Samus.global_position, damage_values["earthquake_strength"], damage_values["earthquake_duration"])
		
		Animator.pause()
		yield(Global.wait(0.5), "completed")
		Animator.resume()
		
		if not ballspark:
			if sprite != null:
				sprite.flip_v = false
#			yield(animations["end"].play(), "completed")
			change_state("jump", {"options": []})
		else:
			change_state("morphball", {"options": []})


func physics_process(_delta: float):
	return

var previous_boosting: = false
var previous_shinespark_charged: = false
func process_speedboooster(_delta: float):
	
	if Samus.boosting:
		if Samus.current_state.id == "run":
			ShinesparkStoreWindow.start(shinespark_store_window)
	
	if Samus.boosting == previous_boosting and Samus.shinespark_charged == previous_shinespark_charged:
		return
	previous_boosting = Samus.boosting
	previous_shinespark_charged = Samus.shinespark_charged
	
	Animator.SpriteContainer.current_profile = "speedboost" if Samus.boosting else null
	
	if Samus.boosting or Samus.shinespark_charged:
		SpeedboostAnimationPlayer.play("speedboost")
	elif SpeedboostAnimationPlayer.current_animation == "speedboost":
		SpeedboostAnimationPlayer.play("reset")

func charge_shinespark():
	ShinesparkUseWindow.start(shinespark_hold_time)
	Samus.shinespark_charged = true
	
func discharge_shinespark():
	ShinesparkUseWindow.stop()
	Samus.shinespark_charged = false
