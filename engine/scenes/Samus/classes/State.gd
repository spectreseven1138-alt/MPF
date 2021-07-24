extends Node
class_name SamusState

var id: String
var Samus: KinematicBody2D

func _init(_Samus: KinematicBody2D, _id: String) -> void:
	id = _id
	Samus = _Samus
	if "Animator" in self:
		self.Animator = Samus.Animator
	if "Physics" in self:
		self.Physics = Samus.Physics
	if "Weapons" in self:
		self.Weapons = Samus.Weapons
	if "animations" in self and id in Global.load_json(PositionalAnimatedSprite.data_json_path):
		self.animations = Samus.Animator.load_from_json(id)
	if "physics_data" in self:
		self.physics_data = Samus.Physics.data[id]

func init_state(_data: Dictionary):
	return true

func change_state(new_state_key: String, data: Dictionary = {}) -> void:
	Samus.change_state(new_state_key, data)

func process(_delta: float) -> void:
	return

func physics_process(_delta: float) -> void:
	return