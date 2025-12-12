extends CanvasLayer
class_name WeatherSystem

signal time_changed(hour: int, is_day: bool)
signal weather_changed(weather_type: String)

enum Weather { CLEAR, RAIN, STORM, SNOW }

# Time settings
var current_time: float = 8.0  # Start at 8 AM
var day_length_minutes: float = 10.0  # Real minutes per game day
var time_speed: float = 24.0 / (day_length_minutes * 60.0)

# Weather
var current_weather: Weather = Weather.CLEAR
var weather_duration: float = 0.0
var weather_timer: float = 0.0

# Visual nodes
var day_night_overlay: ColorRect
var rain_particles: GPUParticles2D
var snow_particles: GPUParticles2D
var lightning_overlay: ColorRect
var weather_sound_timer: float = 0.0

# Lightning
var lightning_timer: float = 0.0
var next_lightning: float = 5.0

func _ready() -> void:
	_create_overlays()
	_create_particles()
	_schedule_weather_change()

func _create_overlays() -> void:
	# Day/Night overlay
	day_night_overlay = ColorRect.new()
	day_night_overlay.name = "DayNightOverlay"
	day_night_overlay.anchors_preset = Control.PRESET_FULL_RECT
	day_night_overlay.color = Color(0, 0, 0, 0)
	day_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(day_night_overlay)
	
	# Lightning flash overlay
	lightning_overlay = ColorRect.new()
	lightning_overlay.name = "LightningOverlay"
	lightning_overlay.anchors_preset = Control.PRESET_FULL_RECT
	lightning_overlay.color = Color(1, 1, 1, 0)
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lightning_overlay)

func _create_particles() -> void:
	# Rain particles
	rain_particles = GPUParticles2D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 200
	rain_particles.lifetime = 1.0
	rain_particles.emitting = false
	rain_particles.position = Vector2(640, -50)
	
	var rain_material = ParticleProcessMaterial.new()
	rain_material.direction = Vector3(0, 1, 0)
	rain_material.spread = 10.0
	rain_material.initial_velocity_min = 400.0
	rain_material.initial_velocity_max = 500.0
	rain_material.gravity = Vector3(0, 200, 0)
	rain_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_material.emission_box_extents = Vector3(700, 10, 0)
	rain_particles.process_material = rain_material
	
	# Rain drop texture
	var rain_img = Image.create(2, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		rain_img.set_pixel(0, y, Color(0.6, 0.7, 0.9, 0.6))
		rain_img.set_pixel(1, y, Color(0.6, 0.7, 0.9, 0.4))
	rain_particles.texture = ImageTexture.create_from_image(rain_img)
	add_child(rain_particles)
	
	# Snow particles
	snow_particles = GPUParticles2D.new()
	snow_particles.name = "SnowParticles"
	snow_particles.amount = 150
	snow_particles.lifetime = 3.0
	snow_particles.emitting = false
	snow_particles.position = Vector2(640, -50)
	
	var snow_material = ParticleProcessMaterial.new()
	snow_material.direction = Vector3(0, 1, 0)
	snow_material.spread = 30.0
	snow_material.initial_velocity_min = 50.0
	snow_material.initial_velocity_max = 100.0
	snow_material.gravity = Vector3(0, 30, 0)
	snow_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	snow_material.emission_box_extents = Vector3(700, 10, 0)
	snow_particles.process_material = snow_material
	
	# Snowflake texture
	var snow_img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for x in range(4):
		for y in range(4):
			var dist = Vector2(x - 1.5, y - 1.5).length()
			if dist < 2:
				snow_img.set_pixel(x, y, Color(1, 1, 1, 0.8))
	snow_particles.texture = ImageTexture.create_from_image(snow_img)
	add_child(snow_particles)

func _process(delta: float) -> void:
	_update_time(delta)
	_update_day_night()
	_update_weather(delta)

func _update_time(delta: float) -> void:
	current_time += time_speed * delta
	if current_time >= 24.0:
		current_time -= 24.0

func _update_day_night() -> void:
	var hour = int(current_time)
	var is_day = current_time >= 6.0 and current_time < 20.0
	
	# Calculate darkness
	var darkness: float = 0.0
	
	if current_time < 5.0:  # Night
		darkness = 0.6
	elif current_time < 6.0:  # Dawn
		darkness = lerp(0.6, 0.0, current_time - 5.0)
	elif current_time < 7.0:  # Early morning
		darkness = lerp(0.0, 0.0, current_time - 6.0)
	elif current_time < 18.0:  # Day
		darkness = 0.0
	elif current_time < 20.0:  # Dusk
		darkness = lerp(0.0, 0.5, (current_time - 18.0) / 2.0)
	else:  # Night
		darkness = lerp(0.5, 0.6, (current_time - 20.0) / 4.0)
	
	# Night color (blue tint)
	var night_color = Color(0.1, 0.1, 0.3, darkness)
	day_night_overlay.color = night_color
	
	time_changed.emit(hour, is_day)

func _update_weather(delta: float) -> void:
	weather_timer += delta
	
	if weather_timer >= weather_duration:
		_schedule_weather_change()
	
	# Update weather effects
	match current_weather:
		Weather.RAIN:
			rain_particles.emitting = true
			snow_particles.emitting = false
		Weather.STORM:
			rain_particles.emitting = true
			snow_particles.emitting = false
			_update_lightning(delta)
		Weather.SNOW:
			rain_particles.emitting = false
			snow_particles.emitting = true
		Weather.CLEAR:
			rain_particles.emitting = false
			snow_particles.emitting = false

func _update_lightning(delta: float) -> void:
	lightning_timer += delta
	
	if lightning_timer >= next_lightning:
		_flash_lightning()
		lightning_timer = 0.0
		next_lightning = randf_range(3.0, 10.0)

func _flash_lightning() -> void:
	lightning_overlay.color = Color(1, 1, 1, 0.8)
	var tween = create_tween()
	tween.tween_property(lightning_overlay, "color", Color(1, 1, 1, 0), 0.15)
	
	# Thunder sound delay (simulate distance)
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	# Play thunder sound here if you have audio

func _schedule_weather_change() -> void:
	weather_timer = 0.0
	weather_duration = randf_range(60.0, 180.0)  # 1-3 minutes
	
	# Random weather with weights
	var roll = randf()
	if roll < 0.5:
		current_weather = Weather.CLEAR
	elif roll < 0.75:
		current_weather = Weather.RAIN
	elif roll < 0.9:
		current_weather = Weather.STORM
	else:
		current_weather = Weather.SNOW
	
	weather_changed.emit(_get_weather_name())

func _get_weather_name() -> String:
	match current_weather:
		Weather.CLEAR: return "Clear"
		Weather.RAIN: return "Rain"
		Weather.STORM: return "Storm"
		Weather.SNOW: return "Snow"
	return "Unknown"

func get_time_string() -> String:
	var hour = int(current_time)
	var minute = int((current_time - hour) * 60)
	var period = "AM" if hour < 12 else "PM"
	var display_hour = hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minute, period]

func is_night() -> bool:
	return current_time < 6.0 or current_time >= 20.0

func set_weather(weather: Weather) -> void:
	current_weather = weather
	weather_changed.emit(_get_weather_name())
