extends Node2D

signal room_loaded

var current_room: Room
var Samus: KinematicBody2D = preload("res://scenes/Samus/Samus.tscn").instance()
var room_container: Node2D = self
var Save: SaveGame = SaveGame.new(SaveGame.debug_save_path)
var transitioning: bool = false

var rooms = {}
const room_directory = "res://scenes/rooms/"

func _ready():
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Register all rooms to the room variable
	var dir = Directory.new()
	assert(dir.open(room_directory) == OK, "Room directory couldn't be opened")
	for file in Global.iterate_directory(dir):
		if dir.dir_exists(file):
			var subdir = Directory.new()
			subdir.open(room_directory + file)
			for subfile in Global.iterate_directory(subdir):
				if subdir.dir_exists(subfile):
					if subdir.file_exists(subfile + "/room.tscn"):
						rooms[file + "/" + subfile] = load(room_directory + file + "/" + subfile + "/room.tscn")
					else:
						push_warning("Room subdirectory '" + file + "' contains an invalid folder")
				else:
					push_warning("Room subdirectory '" + file + "' contains a file: " + subfile)
					
		else:
			push_warning("Room directory contains a file: " + file)
	
	if true:
		Global.save_json(Map.tile_data_path, {})
		for room in rooms.values():
			room.instance().generate_maptiles()
	
func add_samus():
	while current_room == null:
		yield(Global, "process_frame")
	if not Samus in current_room.get_children():
		current_room.add_child(Samus)
		Samus.global_position = Vector2(-256, -240)

func load_room(room_id: String):
	
	assert("/" in room_id and len(room_id.split("/")) == 2)
	var room: Room = rooms[room_id].instance()
	
	current_room = room
	room_container.add_child(room)
	room.add_child(Samus)
	
	var samus_spawn_position: Vector2
	for node in room.World.get_children():
		if node.name == "SpawnPos":
			samus_spawn_position = node.global_position
			break
	
	if samus_spawn_position:
		Samus.global_position = samus_spawn_position
	else:
		assert(false, "No SamusSpawnPosition node registered to room")
	
	emit_signal("room_loaded")

func transition(origin_door: Door):
	
	if transitioning:
		return
	
	transitioning = true
	get_tree().paused = true
	Samus.paused = true
	
	var previous_room = current_room
	current_room = origin_door.target_room_scene.instance()
	
#	yield(previous_room.transitioning() "completed")
	
	# DEBUG | Map tiles don't need to be reloaded on room change normally
	Loader.room_container.call_deferred("add_child", current_room)
	yield(current_room, "ready")
	
	var destination_door: Door
	for door in current_room.Doors:
		if door.id == origin_door.target_id:
			destination_door = door
			break
	# DEBUG
	if not destination_door:
		assert(false, "No destination door found in room")
		return
	
	destination_door.locked = true
	destination_door.open(true)
	
	var spawn_point = origin_door.target_spawn_position.global_position
	var offset = current_room.global_position - destination_door.global_position
	current_room.global_position = spawn_point + offset
	current_room.World.visible = false
	
	# Move Samus to new loaded room and reposition her
	var samus_position = Samus.global_position
	Global.reparent_child(Samus, current_room)
	Samus.global_position = samus_position
	
	# If Samus entered a CameraChunk, animate the transition
	get_tree().paused = false
	yield(Global.wait(0.1, true), "completed")
	if Samus.camerachunk_set_while_paused:
		get_tree().paused = true
		
		Samus.z_index = Enums.Layers.WORLD + 1
		origin_door.fade_out(0.25)
		destination_door.fade_out(0)
		yield(Global.dim_screen(0.25, 1, Enums.Layers.WORLD+1), "completed")
		
		previous_room.queue_free()
		current_room.World.visible = true
		
		yield(Samus.camerachunk_entered(Samus.current_camerachunk, true, 0.45), "completed")
		
		destination_door.fade_in(0.25)
		yield(Global.undim_screen(0.25), "completed")
		
		Samus.z_index = Enums.Layers.SAMUS
		Samus.camerachunk_set_while_paused = false
		
		get_tree().paused = false
	else:
		previous_room.queue_free()
		current_room.World.visible = true
	
	Samus.paused = null
	transitioning = false
	emit_signal("room_loaded")
	destination_door.room_entered()
	
