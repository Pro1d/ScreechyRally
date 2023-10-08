extends RigidBody2D
class_name CarDrift

class Record:
	class Data:
		enum Type { CONTROL = 0x1, BODY_STATE = 0x2 }
		var frame : int # [i32] 0 is before start, 1 is first physics frame
		var type := 0x0 # [i8]
		var control : Array # [4 * f32]
		var body_state : Array # [7 * f32] x;y;r;dx;dy;dr;steering
	var data := [] # Array of Data
	var data_index := 0 # used for replay
	var frame := 0 # number of physics frame
	var end_frame := 0xffffff # at this frame and later: no data & control idle
	var last_control := [0.0, 0.0, 0.0, 0.0]
	var recording := true # or false in replay
	
	static func _make_body_state(car : CarDrift, physics_body_state = null) -> Array:
		if physics_body_state == null:
			physics_body_state = car
		return [
			physics_body_state.transform.origin.x,
			physics_body_state.transform.origin.y,
			physics_body_state.transform.get_rotation(),
			physics_body_state.linear_velocity.x,
			physics_body_state.linear_velocity.y,
			physics_body_state.angular_velocity,
			car.steering,
		]

	static func make_recorder(initial_body : CarDrift) -> Record:
		var r := Record.new()
		var d := Data.new()
		d.frame = 0
		d.type = Data.Type.CONTROL | Data.Type.BODY_STATE
		d.control = [0.0, 0.0, 0.0, 0.0]
		d.body_state = _make_body_state(initial_body)
		r.data.append(d)
		return r

	static func make_replayer(path : String) -> Record:
		var r := Record.new()
		r.recording = false
		r._load_data(path)
		return r

	func stop_and_save(path : String) -> void:
		assert(recording)
		end_frame = frame
		var file := File.new()
		var _e := file.open(path, File.WRITE)
		print_debug("Writing record: ", path)
		if _e:
			printerr("Error writing ", path, " code: ", _e)
			return
		print_debug(path, " duration: ", end_frame)
		file.store_32(end_frame)
		file.store_32(data.size())
		for d in data:
			file.store_32(d.frame)
			file.store_8(d.type)
			if d.type & Data.Type.CONTROL:
				assert(d.control.size() == 4)
				for c in d.control:
					file.store_float(c)
			if d.type & Data.Type.BODY_STATE:
				assert(d.body_state.size() == 7)
				for x in d.body_state:
					file.store_float(x)
		file.close()

	func _load_data(path : String) -> void:
		assert(not recording)
		var file := File.new()
		#print_debug("Opening record: ", path)
		var _e := file.open(path, File.READ)
		if _e:
			printerr("Error reading ", path, " code: ", _e)
			return
		end_frame = file.get_32()
		var data_size := file.get_32()
		print_debug(path, " duration: ", end_frame, " recorded frames: ", data.size())
		data.resize(data_size)
		for i in range(data_size):
			var d := Data.new()
			d.frame = file.get_32()
			d.type = file.get_8()
			if d.type & Data.Type.CONTROL:
				d.control = Array()
				d.control.resize(4)
				for c in range(d.control.size()):
					d.control[c] = file.get_float()
			if d.type & Data.Type.BODY_STATE:
				d.body_state = Array()
				d.body_state.resize(7)
				for x in range(d.body_state.size()):
					d.body_state[x] = file.get_float()
			data[i] = d
		file.close()

	static func read_duration(path : String) -> int:
		var file := File.new()
		#print_debug("Opening record: ", path)
		var _e := file.open(path, File.READ)
		if _e:
			printerr("Error reading ", path, " code: ", _e)
			return -1
		var duration := file.get_32()
		file.close()
		return duration
		
	func next_frame() -> void:
		frame += 1
		if not recording:
			if frame >= end_frame:
				data_index = data.size()
				last_control = [0.0, 0.0, 0.0, 0.0]
			elif data_index + 1< data.size() and frame >= data[data_index + 1].frame:
				data_index += 1
				if data[data_index].type & Data.Type.CONTROL:
					last_control = data[data_index].control

	func add_controls(control : Array) -> void:
		assert(recording)
		assert(len(control) == 4)
		if frame >= end_frame:
			return
		var has_changed := false
		for i in range(4):
			if last_control[i] != control[i]:
				has_changed = true
				break
		if has_changed:
			last_control = control
			var d := Data.new()
			d.frame = frame
			d.type = Data.Type.CONTROL
			d.control = control
			data.append(d)
	
	func add_body_state(car : CarDrift, physics_body_state : Physics2DDirectBodyState = null, force_write : bool = false) -> void:
		var state := _make_body_state(car, physics_body_state)
		assert(recording)
		if frame >= end_frame:
			return
		if frame % 50 == 0 or force_write:
			var d : Data = data[-1]
			if d.frame != frame:
				d = Data.new()
				d.frame = frame
				data.append(d)
			d.type |= Data.Type.BODY_STATE
			d.body_state = state

	func get_controls() -> Array:
		assert(not recording)
		return last_control

	func get_body_state(): # -> [Transform2D, Vector2, float] or null
		assert(not recording)
		if data_index < data.size():
			var d : Data = data[data_index]
			if d.frame == frame and (d.type & Data.Type.BODY_STATE):
				return [
					Transform2D(d.body_state[2], Vector2(d.body_state[0], d.body_state[1])),
					Vector2(d.body_state[3], d.body_state[4]),
					d.body_state[5],
					d.body_state[6]
				]
		return null

enum ControlMode { ENABLED, DISABLED, REPLAY }

const steering_accel := 3.0
const max_rotation_speed := 2 * PI * 0.65
const angular_accel := 11.0
const max_speed := 400.0
const engine_power := 240.0
const backward_factor := 0.6
const friction_coeff := 400.0 # 550.0

export(Vector2) var cinematic_center_offset := Vector2(-26, 0)
export(int, 0, 1) var player_id := 1
export(Color) var color := Color.white setget _set_color
export(float, 0, 1) var ghost_alpha := 0.3
# When is_ghost is true, display is transparent and collision are disabled
export(bool) var is_ghost := false setget _set_ghost_mode
export(ControlMode) var control_mode : int = ControlMode.ENABLED

var previous_linear_velocity := Vector2.ZERO
var steering := 0.0 # in range [-1; 1]

var reset_position = null # Transform2D
var _erase_state = null # null or [Transform2D, Vector2, float, float]
var _record : Record = null

func _ready() -> void:
	var _e = connect("body_entered", self, "_on_collision")
	_set_engine_sound(0.0, true)
	$DriftTrailEmitterLeft.world = get_parent()
	$DriftTrailEmitterRight.world = get_parent()
	$EngineSound.play(randf())

func _process(_delta : float) -> void:
	$ControlAnchor/SpeedLabel.text = str(round(linear_velocity.length()))
	$ControlAnchor.global_rotation = 0
	if control_mode == ControlMode.ENABLED:
		var control_index := ControlManager.player_assignment(player_id)
		var action_prefix := ControlManager.action_prefix(control_index)
		if Input.is_action_just_pressed(action_prefix + "reset"):
			if reset_position != null:
				teleport(reset_position)

func _physics_process(delta : float) -> void:
	self.previous_linear_velocity = self.linear_velocity
	
	if _record != null and control_mode != ControlMode.DISABLED: # TODO start_recording()
		_record.next_frame()
	
	var lon_direction := transform.x
	var lat_direction := transform.y

	var target_speed := 0.0
	var target_steering := 0.0
	var brake := false
	var free_wheel := true
	
	if control_mode != ControlMode.DISABLED:
		var control_index := ControlManager.player_assignment(player_id)
		var action_prefix := ControlManager.action_prefix(control_index)
		# var action_boost := Input.get_action_strength(action_prefix + "boost") > 0
		var action_forward := Input.get_action_strength(action_prefix + "up")
		var action_backward := Input.get_action_strength(action_prefix + "down")
		var action_left := Input.get_action_strength(action_prefix + "left")
		var action_right := Input.get_action_strength(action_prefix + "right")
		if _record != null:
			if control_mode == ControlMode.REPLAY:
				var actions := _record.get_controls()
				action_forward = actions[0]
				action_backward = actions[1]
				action_left = actions[2]
				action_right = actions[3]
			else:
				_record.add_controls([
					action_forward,
					action_backward,
					action_left,
					action_right
				])

		target_steering = action_right - action_left
		
		free_wheel = false
		if  action_forward and action_backward:
			brake = true
		elif action_forward:
			target_speed = max_speed
			if linear_velocity.dot(lon_direction) < 1e-4:
				brake = true
		elif action_backward:
			target_speed = -max_speed * backward_factor
			if linear_velocity.dot(lon_direction) > 1e-4:
				brake = true
		else:
			free_wheel = true

	var friction_force := friction_coeff * mass
	var target_velocity := target_speed * lon_direction
	if free_wheel:
		target_velocity += lon_direction * linear_velocity.dot(lon_direction)
	# Velocity of the wheels relatively to velocity of the car
	var rel_velocity := target_velocity - linear_velocity
	var lon_rel_speed := rel_velocity.dot(lon_direction)
	var lat_rel_speed := rel_velocity.dot(lat_direction)
	var lat_drift_threshold := delta * friction_force * 4 # 20.0
	var lon_drift_threshold := 200.0
	var rel_velocity_grip := (
		lat_direction * sign(lat_rel_speed) * max(0, abs(lat_rel_speed) - lat_drift_threshold)
		+ lon_direction * sign(lon_rel_speed) * max(0, abs(lon_rel_speed) - lon_drift_threshold))
	var drift := rel_velocity_grip.length() > 1e-3
	var engine_force := engine_power * mass
	var max_lon_accel := min(friction_force, engine_force)
	if brake:
		var rel_speed := rel_velocity.length()
		if rel_speed > 1e-4:
			apply_central_impulse(
				rel_velocity * min(friction_force * delta / rel_speed, 1.0))
	else:
		apply_central_impulse(
			lat_direction * sign(lat_rel_speed) * min(friction_force * delta, abs(lat_rel_speed))
			+ lon_direction * sign(lon_rel_speed) * min(max_lon_accel * delta, abs(lon_rel_speed)))
	
	steering += clamp(target_steering - steering, -steering_accel * delta, steering_accel * delta)
	var steering_effectiveness := clamp(lon_direction.dot(linear_velocity) / 400.0, -1, 1)
	var target_angular_velocity := steering * max_rotation_speed *  steering_effectiveness
#	angular_velocity += clamp(
#		target_angular_velocity - angular_velocity, -angular_accel * delta, angular_accel * delta)

	var angular_impulse := clamp(
		target_angular_velocity - angular_velocity,
		-angular_accel * delta,
		angular_accel * delta) * inertia
	var r := 100.0
	apply_impulse(cinematic_center_offset + Vector2(0, r), Vector2(-angular_impulse / r, 0))
	apply_impulse(cinematic_center_offset + Vector2(0, -r), Vector2(angular_impulse / r, 0))
	
	# Sound and display
	_update_wheel_display_angle()
	if drift != $DriftSound.playing:
		$DriftSound.playing = drift
	if drift:
		_set_drift_sound(rel_velocity_grip.length())
	$DriftTrailEmitterLeft.emitting = drift
	$DriftTrailEmitterRight.emitting = drift
	$DriftFogParticles.emitting = drift
	$SpriteBrakeLight.visible = brake
	var engine_rpm := abs(target_speed) / max_speed if not brake and not free_wheel else 0.0
	_set_engine_sound(engine_rpm)

func _integrate_forces(state : Physics2DDirectBodyState):
	var state_erased := false
	if _erase_state != null:
		state.transform = _erase_state[0]
		state.linear_velocity = _erase_state[1]
		state.angular_velocity = _erase_state[2]
		steering = _erase_state[3]
		_erase_state = null
		state_erased = true
	
	if _record != null: # TODO start_recording()
		match control_mode:
			ControlMode.REPLAY:
				var s = _record.get_body_state()
				if s != null:
					state.transform = s[0]
					state.linear_velocity = s[1]
					state.angular_velocity = s[2]
					steering = s[3]
			ControlMode.ENABLED:
				_record.add_body_state(self, state, state_erased)

func _set_engine_sound(engine_rpm : float, reset : bool = false) -> void:
	var change_speed := 1.0 if reset else 0.1
	var target_volume_db := 12 * engine_rpm - 10 - (15 if is_ghost else 0)
	$EngineSound.volume_db += (target_volume_db - $EngineSound.volume_db) * change_speed
	$EngineSound.pitch_scale += (0.5 + engine_rpm * 0.2 - $EngineSound.pitch_scale) * change_speed

func _set_drift_sound(velocity_grip : float) -> void:
	$DriftSound.volume_db = -20 + 20 * clamp(velocity_grip / 200, 0, 1) - (15 if is_ghost else 0)
	$DriftSound.pitch_scale = 1 + 0.2 * clamp(velocity_grip / 200, 0, 1)

func _update_wheel_display_angle() -> void:
	var max_steering_display_angle := PI / 5
	$FrontLeftWheelPolygon.rotation = steering * max_steering_display_angle
	$FrontRightWheelPolygon.rotation = steering * max_steering_display_angle

func _on_collision(body):
	var other_previous_velocity := Vector2.ZERO
	var other_velocity := Vector2.ZERO
	
	if body.get("previous_linear_velocity") != null:
		other_previous_velocity = body.get("previous_linear_velocity")
	if body.get("linear_velocity") != null:
		other_velocity = body.get("linear_velocity")

	var velocity_change := self.linear_velocity - self.previous_linear_velocity
	var other_velocity_change := other_velocity - other_previous_velocity

	var collision_normal := (velocity_change + other_velocity_change).normalized()
	var projected_velocities = abs(collision_normal.dot(previous_linear_velocity) - collision_normal.dot(other_previous_velocity)) 

	var sound_volume := range_lerp(projected_velocities*projected_velocities/200, 0, 200, -40, 0)
	sound_volume = clamp(sound_volume - 10, -30, -10)

	$CollisionSound.volume_db = sound_volume  - (15 if is_ghost else 0)
	$CollisionSound.play()

func teleport(pose : Transform2D) -> void:
	_erase_state = [pose, Vector2.ZERO, 0.0, 0.0]

func save_reset_position(pose = null) -> void:
	# pose as Transform2D
	reset_position = transform if pose == null else pose

func reset(pose : Transform2D) -> void:
	if _record != null and not _record.recording:
		# TODO assert(pose == null)
		pose = _record.get_body_state()[0]

	save_reset_position(pose)
	teleport(pose)
	control_mode = ControlMode.DISABLED

func activate(replay : bool = false):
	control_mode = ControlMode.REPLAY if replay else ControlMode.ENABLED

# Record effectively starts when control_mode is set to ControlMode.ENABLED
func enable_recording() -> void:
	# FIXME dirty hack
	if _erase_state != null:
		transform = _erase_state[0]
		linear_velocity = _erase_state[1]
		angular_velocity = _erase_state[2]
		steering = _erase_state[3]
		assert(transform.get_origin().distance_to(_erase_state[0].get_origin())  < 1e-4)
		assert(abs(transform.get_rotation()-_erase_state[0].get_rotation())  < 1e-4)
	_record = Record.make_recorder(self)

# Set control_mode to ControlMode.REPLAY to start replaying, or call activate(true)
func load_record(path : String) -> void:
	_record = Record.make_replayer(path)

func save_record(path : String) -> void:
	_record.stop_and_save(path)

func _set_ghost_mode(ghost : bool) -> void:
	is_ghost = ghost
	if is_ghost:
		collision_mask &= ~CollisionLayers.Bit.CAR
		collision_layer &= ~CollisionLayers.Bit.CAR
		modulate.a = ghost_alpha
		z_index = 9
	else:
		collision_mask |= CollisionLayers.Bit.CAR
		collision_layer |= CollisionLayers.Bit.CAR
		modulate.a = 1.0
		z_index = 10

func _set_color(c : Color) -> void:
	color = c
	$SpriteModulate.modulate = c

func get_control_anchor() -> Node2D:
	return $ControlAnchor as Node2D
