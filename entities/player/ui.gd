extends Control

@onready var reload_delay : Timer = $"../ReloadDelay"
@onready var player : CharacterBody3D = get_parent()
@onready var gun_delay_bar := $Weaponpanel/Cooldown_bar
@onready var pause_menu = $"Pause_menu"
@onready	 var weapon_sprite = $WeaponSprite

var is_paused = false
var can_anim_change = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pause_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_reticule()
	$Weaponpanel/Ammo_txt.set_text(str(snapped(player.current_gun_ammo, 1)))

	if not reload_delay.is_stopped():
		gun_delay_bar.value = 1.0 - reload_delay.time_left / reload_delay.wait_time
		#$Gun.show()
	else:
		gun_delay_bar.value = 1.0
		#$Gun.hide()

	
	if player.current_weapon.is_beam and can_anim_change:
		if player.current_gun_ammo <= 0 and $"../ReloadDelay".is_stopped():
			weapon_sprite.play("overcharged")
			can_anim_change = false
		else:
			weapon_sprite.play("hold")
	
	update_to_viewport_size()
	
func _input(event):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	
func change_reticule():
	for reticule in $Reticule.get_children():
		reticule.hide()
	
	if player.current_weapon.is_full_auto and not player.current_weapon.is_beam and not player.current_weapon.is_projectile:
		$Reticule/FullAuto.show()
		var base_scale = 1.0 / player.current_weapon.spread_speed
		var spread_factor = base_scale + (player.shoot_hold_time * player.current_weapon.spread_speed)
		var target_scale = base_scale + spread_factor * player.current_weapon.spread_speed
		var current_scale = $Reticule/FullAuto.scale.x  # Assuming uniform scaling
		var smooth_scale = lerp(current_scale, target_scale, 0.1)  # Adjust the factor (0.1) for smoothness
		$Reticule/FullAuto.scale = Vector2(smooth_scale, smooth_scale)
	elif player.current_weapon.is_beam:
		$Reticule/Beam.show()
	elif player.current_weapon.is_projectile:
		$Reticule/Projectile.show()
	else:
		$Reticule/Regular.show()
		
func toggle_pause():
	is_paused = not is_paused
	if is_paused:
		# get_tree().paused = true  # Pause the game logic
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show the mouse cursor
		pause_menu.visible = true
	else:
		# get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_menu.visible = false


func _on_weapon_sprite_animation_finished() -> void:
	can_anim_change = true

func scroll_weapon_ui() -> void:
	var weapon_index = (player.weapon_inventory.weapon_list.find(player.current_weapon) + 1) % player.weapon_inventory.weapon_list.size()
	var panel = $Weaponpanel/FillPanel
	print(weapon_index)
	
	# Load the texture based on weapon index or weapon type
	var texture_path = ""
	match weapon_index:
		1:
			texture_path = "res://assets/sprites/ui weapon fill1.png"
		2:
			texture_path = "res://assets/sprites/ui weapon fill2.png"
		3:
			texture_path = "res://assets/sprites/ui weapon fill3.png"
		_:
			texture_path = "res://assets/sprites/ui weapon fill3.png"
	
	var texture = load(texture_path)
	if texture:
		var new_stylebox = StyleBoxTexture.new()
		new_stylebox.texture = texture
		panel.add_theme_stylebox_override("panel", new_stylebox)

func update_to_viewport_size():
	weapon_sprite.scale = Vector2(get_viewport().size.x / 480, get_viewport().size.y / 270)
