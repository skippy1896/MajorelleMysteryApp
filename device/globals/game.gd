extends Node

var vm
var player
var mode = "default"
var action_menu = null
var inventory
export(String,FILE) var fallbacks_path = ""
export var inventory_enabled = true setget set_inventory_enabled
export var buttons_enabled = true setget set_buttons_enabled
var fallbacks
var check_joystick = false
var joystick_mode = false
var min_interact_dist = 50*50
var last_obj = null

var current_action = ""
var current_tool = null

var click
var click_anim

var camera
export var camera_limits = Rect2()

func set_mode(p_mode):
	mode = p_mode

func mouse_enter(obj):
	var text
	var tt = obj.get_esctooltip()
	if current_action == "use" && current_tool != null:
		text = tr(current_action + ".combine_id")
		text = text.replace("%2", tr(tt))
		text = text.replace("%1", tr(current_tool.get_esctooltip()))
	elif current_action != "" :
		text = tr(current_action+".id")
		text = text.replace("%1", tr(tt))
	elif obj.inventory:
		var action = inventory.get_action()
		if action == "":
			action = current_action
		text = tr(action + ".id")
		text = text.replace("%1", tr(tt))
	else:
		text = tt
	get_tree().call_group("hud", "set_tooltip", text)
	vm.hover_begin(obj)

# warning-ignore:unused_argument
func mouse_exit(obj):
	var text
	#var tt = obj.get_tooltip()
	if current_action != "" && current_tool != null:
		text = tr(current_action + ".id")
		text = text.replace("%1", tr(current_tool.get_esctooltip()))
	else:
		text = ""
	get_tree().call_group("hud", "set_tooltip", text)
	vm.hover_end()

func clear_action():
	current_tool = null

func clear_current_action():
	current_action = null

func set_current_action(p_act):
	if p_act != current_action:
		set_current_tool(null)
	current_action = p_act

func get_current_action():
	return current_action

func set_current_tool(p_tool):
	current_tool = p_tool

func clicked(obj, pos):
	# If multiple areas are clicked at once, an item_background "wins"
	if obj is Area2D:
		for area in obj.get_overlapping_areas():
			if area.has_method("is_clicked") and area.is_clicked():
				return
	joystick_mode = false
	if !vm.can_interact():
		return
	if player == null:
		player = self
	if mode == "default":
		var action = obj.get_action()
		#action_menu.stop()
		if action == "walk":

			#click.set_position(pos)
			#click_anim.play("click")
			if player == self:
				return
			player.walk_to(pos)
			get_tree().call_group("hud", "set_tooltip", "")

		elif obj.inventory:
			if current_action == "use" && obj.use_combine && current_tool == null:
				set_current_tool(obj)
				get_tree().call_group("verb_menu", "something_picked")
			else:
				interact([obj, current_action, current_tool])
				printt("1 ",obj.name,current_action,current_tool)
				current_action=""
				get_tree().call_group("verb_menu", "reset_mouse",current_action)
				
		# Added Use_Combine functionality for items that are not in the inventory /sh
		elif !obj.inventory && current_action == "use":
			if  obj.use_combine && current_tool == null:
				set_current_tool(obj)
				get_tree().call_group("verb_menu", "something_picked")
			else:
				printt("2 ",obj.name,current_action,current_tool)
				if obj.is_in_group("puzzle") or obj.get_parent().is_in_group("puzzle"):
					interact([obj, current_action, current_tool])
					get_tree().call_group("verb_menu", "reset_picked")
				else:
					interact([obj, current_action, current_tool])
					current_action=""
					get_tree().call_group("verb_menu", "reset_mouse",current_action)
					printt("Mouse should be reset.")
		
		elif action != "":
			player.interact([obj, action, current_tool])
			printt("3 ",obj.name,action,current_tool)
			action=""
			get_tree().call_group("verb_menu", "reset_mouse",current_action)
			printt("Mouse should be reset.")

		elif current_action != "":
			player.interact([obj, current_action, current_tool])
			printt("4 ",obj.name,current_action,current_tool)
			current_action=""
			get_tree().call_group("verb_menu", "reset_mouse",current_action)
			printt("Mouse should be reset.")
		
		elif action_menu == null:

			# same as action == "walk"
			if player == self:
				return
			player.walk_to(pos)
			get_tree().call_group("hud", "set_tooltip", "")

		elif obj.use_action_menu && action_menu != null:
			spawn_action_menu(obj)

func spawn_action_menu(obj):
	if action_menu == null:
		return
	action_menu.show()
	var pos
	if obj.has_node("action_menu_pos"):
		pos = obj.get_node("action_menu_pos").get_global_position()
	else:
		pos = obj.get_global_position()
	action_menu.set_position(pos)
	action_menu.start(obj)
	#obj.grab_focus()

func action_menu_selected(obj, action):
	if action == "use" && obj.get_action() != "":
		action = obj.get_action()
	if player != null:
		player.interact([obj, action])
	else:
		interact([obj, action])
	action_menu.stop()

func interact(p_params):
	if mode == "default":
		var obj = p_params[0]
		clear_action()
		var action = p_params[1]
		if !action:
			action = obj.get_action()

		if p_params.size() > 2:
			clear_action()
			if obj == p_params[2]:
				return
			#inventory.close()
			activate(obj, action, p_params[2])
			printt("Activated this",obj.name,action,p_params[2])
		else:
			#inventory.close()
			activate(obj, action)
			printt("Activated that",obj.name,action)
			clear_action()
		return

func activate(obj, action, param = null):
	if !vm.can_interact():
		#printt("******************** vm can't interact during activate")
		#print_stack()
		return

	if !obj.activate(action, param):
		if param != null: # try opposite way
			if param.activate(action, obj):
				return
		fallback(obj, action, param)

# warning-ignore:unused_argument
func fallback(obj, action, param = null):
	if fallbacks == null:
		return
	var comb = action
	if typeof(param) != typeof(null):
		comb = action + " " + param.global_id
		if comb in fallbacks:
			vm.run_event(fallbacks[comb])
			return
	if action in fallbacks:
		vm.run_event(fallbacks[action])
		return
	vm.report_errors(fallbacks_path, ["Invalid action " + comb + " in fallbacks."])

func scene_input(event):
	if event.is_action("quick_save") && event.is_pressed() && !event.is_echo():
		vm.request_autosave()
	if event is InputEventJoypadMotion:
		if event.axis == 0 || event.axis == 1:
			joystick_mode = true
			check_joystick = true
			set_process(true)

	if event is InputEventMouseButton && !event.is_pressed() && event.button_index == BUTTON_LEFT:
		if vm.drag_object != null:
			vm.drag_end()


	if event.is_action("menu_request") && event.is_pressed() && !event.is_echo():
		if vm.can_save() && vm.can_interact() && vm.menu_enabled():
			get_node("/root/main").load_menu(ProjectSettings.get("ui/main_menu"))
		else:
			#get_tree().call_group(0, "game", "ui_blocked")
			if vm.menu_enabled():
				get_node("/root/main").load_menu(ProjectSettings.get("ui/in_game_menu"))
			else:
				get_tree().call_group("game", "ui_blocked")


# warning-ignore:unused_argument
func _process(time):
	if !vm.can_interact():
		check_joystick = false
		return

	if player == null || player == self:
		return
	if joystick_mode:
		var objs = vm.get_registered_objects()
		var mobj = null
		var mdist
		var pos = player.get_position()
		for key in objs:
			if key == "player":
				continue
			if !objs[key].is_type("Control"):
				continue
			if !objs[key].is_visible():
				continue
			if objs[key].tooltip == "":
				continue
			var objpos = objs[key].get_interact_position()
			var odist = pos.distance_squared_to(objpos)
			if typeof(mobj) == typeof(null):
				mobj = objs[key]
				mdist = odist
			else:
				if odist < mdist:
					mdist = odist
					mobj = objs[key]
		if typeof(mobj) != typeof(null):
			if mdist < min_interact_dist:
				if true || mobj != last_obj:
					spawn_action_menu(mobj)
					mouse_enter(mobj)
					last_obj = mobj
			else:
				#action_menu.stop()
				mouse_exit(mobj)
				last_obj = null

	if !check_joystick:
		return

	var dir = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1));
	if dir.length_squared() < 0.1:
		check_joystick = false
		return

	player.walk_to(player.get_position() + dir * 20)

func set_inventory_enabled(p_enabled):
	inventory_enabled = p_enabled
	if !has_node("hud_layer/hud/inv_toggle"):
		return
	if inventory_enabled:
		get_node("hud_layer/hud/inventory").show()
	else:
		get_node("hud_layer/hud/inventory").hide()

func set_buttons_enabled(p_enabled):
	buttons_enabled = p_enabled

func set_camera_limits():
	var cam_limit = camera_limits
	if camera_limits.size.x == 0 && camera_limits.size.y == 0:
		var p = get_parent()
		var area = Rect2()
		for i in range(0, p.get_child_count()):
			var c = p.get_child(i)
			if !(c is preload("res://globals/background.gd")):
				continue
			var pos = c.get_global_position()
			var size = c.get_size()
			area = area.expand(pos)
			area = area.expand(pos + size)

		camera.set_limit(MARGIN_LEFT, area.position.x)
		camera.set_limit(MARGIN_RIGHT, area.position.x + area.size.x)
		var cam_top = area.position.y # - get_node("/root/main").screen_ofs.y
		camera.set_limit(MARGIN_TOP, cam_top)
		camera.set_limit(MARGIN_BOTTOM, cam_top + area.size.y)

		if area.size.x == 0 || area.size.y == 0:
			area.size.x = 1600
			area.size.y = 1200

		printt("setting camera limits from scene ", area)
		cam_limit = area
	else:
		camera.set_limit(MARGIN_LEFT, camera_limits.position.x)
		camera.set_limit(MARGIN_RIGHT, camera_limits.position.x + camera_limits.size.x)
		camera.set_limit(MARGIN_TOP, camera_limits.position.y)
		camera.set_limit(MARGIN_BOTTOM, camera_limits.position.y + camera_limits.size.y + get_node("/root/main").screen_ofs.y * 2)
		printt("setting camera limits from parameter ", camera_limits)

	camera.set_offset(get_node("/root/main").screen_ofs * 2)
	vm.set_cam_limits(cam_limit)

	#vm.update_camera(0.000000001)

func load_hud():
	var hres = vm.res_cache.get_resource(vm.get_hud_scene())
	get_node("hud_layer/hud").replace_by_instance(hres)
	inventory = get_node("hud_layer/hud/inventory")
	if inventory_enabled:
		get_node("hud_layer/hud/inventory").show()
	else:
		get_node("hud_layer/hud/inventory").hide()
	if buttons_enabled:
		get_node("hud_layer/hud/verb_menu").show()
	else:
		get_node("hud_layer/hud/verb_menu").hide()


func _ready():
	add_to_group("game")
	vm = get_tree().get_root().get_node("vm")
	#player = get_node("../player")
	if has_node("action_menu"):
		action_menu = get_node("action_menu")
	if fallbacks_path != "":
		fallbacks = vm.compile(fallbacks_path)

	if has_node("click"):
		click = get_node("click")
	if has_node("click_anim"):
		click_anim = get_node("click_anim")
	#set_process_input(true)

	camera = get_node("camera")

	vm.set_camera(camera)

	call_deferred("set_camera_limits")
	call_deferred("load_hud")
