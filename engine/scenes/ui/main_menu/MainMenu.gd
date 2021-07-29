extends Control

enum STATES {TITLE, SAVE_SELECTION, SETTINGS, CREDITS, QUIT_CONFIRM, TRANSITIONING}
var state: int = STATES.TITLE

# Title state
const title_option_selected_modulate: Color = Color(1, 1, 1, 1)
const title_option_unselected_modulate: Color = Color(1, 1, 1, 0.25)
var title_selected_option: int = 0 

# Save selection state
var save_selected_option: int = 0
var save_games: Array = []
var savefile_animation_played: bool = false

# Settings state
var settings_animation_played: bool = false

func _process(delta: float):
	var pad_vector: Vector2 = Shortcut.get_pad_vector("just_pressed")
	$Background/bg_planet.rotation_degrees += delta * 0.5
	
	match state:
		STATES.TITLE: process_title(delta, pad_vector)
		STATES.SAVE_SELECTION: process_saveselection(delta, pad_vector)
		STATES.SETTINGS: process_settings(delta, pad_vector)

func process_title(delta: float, pad: Vector2):
	
	if pad.y != 0:
		if title_selected_option < 0:
			title_selected_option = 0
		else:
			$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
			title_selected_option = wrapi(title_selected_option + pad.y, 0, $Title/Options.get_child_count())
		
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_selected_modulate
	
	if $MainButtonPrompts/AcceptButtonPrompt.just_pressed():
		$Title/Options.get_child(title_selected_option).get_node("Button").emit_signal("pressed")

func title_option_mouse_hover(entered: bool, option: int):
	if entered and option != title_selected_option:
		if title_selected_option >= 0:
			$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
		title_selected_option = option
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_selected_modulate
	elif not entered and option == title_selected_option:
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
		title_selected_option = -1

func selectsave_button_pressed():
	state = STATES.TRANSITIONING
	
	if save_selected_option != 0:
		$SaveSelection/SaveContainer.get_child(save_selected_option).current = false
	save_selected_option = 0
	$SaveSelection/SaveContainer.get_child(save_selected_option).current = true
	
	$Tween.interpolate_property($Title, "modulate:a", 1.0, 0.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Title.visible = false
	
	var savefile_animation = not savefile_animation_played
	if savefile_animation:
		savefile_animation_played = true
		for save in $SaveSelection/SaveContainer.get_children():
			save.modulate.a = 0.0
	
	$MainButtonPrompts/CancelButtonPrompt.set_visibility(true, true)
	$SaveSelection.modulate.a = 0.0
	$SaveSelection.visible = true
	$Tween.interpolate_property($SaveSelection, "modulate:a", 0.0, 1.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	if savefile_animation:
#		for save in $SaveSelection/SaveContainer.get_children():
#			save.modulate.a = 0.0
		for save in $SaveSelection/SaveContainer.get_children():
			save.margin_left = rect_size.x - $SaveSelection/SaveContainer.rect_global_position.x
			save.modulate.a = 1.0
			$Tween.interpolate_property(save, "margin_left", rect_size.x - $SaveSelection/SaveContainer.rect_global_position.x, 0.0, 0.15, Tween.TRANS_EXPO, Tween.EASE_OUT)
			$Tween.start()
			yield($Tween, "tween_completed")
	
	state = STATES.SAVE_SELECTION

func settings_button_pressed():
	state = STATES.TRANSITIONING
	$MainButtonPrompts/CancelButtonPrompt.set_visibility(true, true)
	
	$Settings/SettingsMenu.init(!settings_animation_played)
	settings_animation_played = true
	
	yield(transition_controls($Title, $Settings), "completed")
	state = STATES.SETTINGS
func docs_button_pressed():
	print("Docs | TODO")
func quit_button_pressed():
	get_tree().quit()

func process_saveselection(_delta: float, pad: Vector2):
	if pad.y != 0:
		if save_selected_option < 0:
			save_selected_option = 0
		else:
			$SaveSelection/SaveContainer.get_child(save_selected_option).current = false
			save_selected_option = wrapi(save_selected_option + pad.y, 0, $SaveSelection/SaveContainer.get_child_count())
		$SaveSelection/SaveContainer.get_child(save_selected_option).current = true
	
	if $MainButtonPrompts/AcceptButtonPrompt.just_pressed():
		save_option_pressed(save_selected_option)
	elif $MainButtonPrompts/CancelButtonPrompt.just_pressed():
		state = STATES.TRANSITIONING
		
		$MainButtonPrompts/CancelButtonPrompt.set_visibility(false, true)
		yield(transition_controls($SaveSelection, $Title), "completed")
		
		state = STATES.TITLE

func save_option_mouse_hover(entered: bool, option: int):
	if entered and option != save_selected_option:
		if save_selected_option >= 0:
			$SaveSelection/SaveContainer.get_child(save_selected_option).current = false
		save_selected_option = option
		$SaveSelection/SaveContainer.get_child(save_selected_option).current = true
	elif not entered and option == save_selected_option:
		$SaveSelection/SaveContainer.get_child(save_selected_option).current = false
		save_selected_option = -1
func save_option_pressed(option: int):
	state = STATES.TRANSITIONING
	
	$Overlay/ColorRect.color = Color(0, 0, 0, 0)
	$Overlay/ColorRect.visible = true
	$Tween.interpolate_property($Overlay/ColorRect, "color:a", $Overlay/ColorRect.color.a, 1.0, 0.3)
	$Tween.start()
	yield(Global.wait(0.31, true), "completed")
	
	Loader.load_savegame($SaveSelection/SaveContainer.get_child(option).saveGame)
	
	for child in get_children():
		if "visible" in child:
			child.visible = false
	
	yield(Global.wait(0.2, true), "completed")
	$Tween.interpolate_property($Overlay/ColorRect, "color:a", $Overlay/ColorRect.color.a, 0.0, 0.3)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	queue_free()

func process_settings(delta: float, pad: Vector2):
	var quit = $Settings/SettingsMenu.process(
		delta, pad, 
		$MainButtonPrompts/AcceptButtonPrompt.just_pressed(), 
		$MainButtonPrompts/CancelButtonPrompt.just_pressed(),
		$Settings/ButtonPrompts/SaveButtonPrompt.just_pressed(),
		$Settings/ButtonPrompts/ResetButtonPrompt.just_pressed()
		)
	while quit is GDScriptFunctionState:
		quit = yield(quit, "completed")
	if quit:
		state = STATES.TRANSITIONING
		$MainButtonPrompts/CancelButtonPrompt.set_visibility(false, true)
		yield(transition_controls($Settings, $Title), "completed")
		state = STATES.TITLE

func _ready():
	
	$MainButtonPrompts/CancelButtonPrompt.set_visibility(false, true)
	$AnimationPlayer.play("reset")
	
	# Title state
	for option in $Title/Options.get_children():
		option.get_node("Button").connect("mouse_entered", self, "title_option_mouse_hover", [true, option.get_position_in_parent()])
		option.get_node("Button").connect("mouse_exited", self, "title_option_mouse_hover", [false, option.get_position_in_parent()])
	for option in $Title/Options.get_children():
		if option.get_position_in_parent() == title_selected_option:
			option.self_modulate = title_option_selected_modulate
		else:
			option.self_modulate = title_option_unselected_modulate
	
	$Title/Options/SelectSave/Button.connect("pressed", self, "selectsave_button_pressed")
	$Title/Options/Settings/Button.connect("pressed", self, "settings_button_pressed")
	$Title/Options/Docs/Button.connect("pressed", self, "docs_button_pressed")
	$Title/Options/Quit/Button.connect("pressed", self, "quit_button_pressed")
	
	# Save selection state
	for save in $SaveSelection/SaveContainer.get_children():
		save.init(SaveGame.new(Loader.get_savefile_path(save.get_position_in_parent())))
		save.get_node("Button").connect("mouse_entered", self, "save_option_mouse_hover", [true, save.get_position_in_parent()])
		save.get_node("Button").connect("mouse_exited", self, "save_option_mouse_hover", [false, save.get_position_in_parent()])
		save.get_node("Button").connect("pressed", self, "save_option_pressed", [save.get_position_in_parent()])
	
	return
	var save_point: Dictionary = Loader.loaded_save.get_data_key(["save_point"])
	Loader.load_room(save_point["room_id"], true, {"preview": true})
#	yield(play_spawn_animation(save_point), "completed")
	queue_free()

func play_spawn_animation(save_point: Dictionary):
	Notification.allow_new_notifications = false
	Notification.clear_all()
	var Samus: KinematicBody2D = Loader.Samus
	Samus.visible = false
	Samus.paused = true
	
	yield(Loader.current_room.save_stations[save_point["save_station_id"]].spawn_samus(), "completed")
	Notification.allow_new_notifications = true

func transition_controls(current: Control, next: Control):
	
	$Tween.interpolate_property(current, "modulate:a", current.modulate.a, 0.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	current.visible = false
	
	next.modulate.a = 0
	next.visible = true
	$Tween.interpolate_property(next, "modulate:a", 0.0, 1.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	
