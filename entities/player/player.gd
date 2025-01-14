extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.2  # Adjust to change the rotation sensitivity

@onready var camera = $Camera3D
@onready var weapon_position = $Camera3D/Weapon_position
@onready var weapon_inventory = preload("res://weapons/weapon_inventory.tres")

var current_weapon: WeaponResource = null  # The current equipped weapon
var current_gun_ammo :float 
var shoot_hold_time: float = 0.0
var can_shoot = true  # Track if the player can shoot
var camera_recoil_offset :Vector3 = Vector3(0,0,0)
var current_beam: Node3D = null
var last_ray_end: Vector3 = Vector3.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Example weapon setup
	current_weapon = weapon_inventory.weapon_list[0]  # Load an example weapon
	current_gun_ammo = current_weapon.max_ammo


func _physics_process(delta: float) -> void:
	if $UI.is_paused:
		return  # Don't process movement or other gameplay logic when paused

	movemement(delta)
	
	if ((Input.is_action_just_pressed("shoot") and not current_weapon.is_full_auto) \
	 or (Input.is_action_pressed("shoot") and current_weapon.is_full_auto)) \
	 and not $UI.is_paused and can_shoot and $ReloadDelay.is_stopped():
		can_shoot = false  # Prevent multiple calls
		current_gun_ammo = current_weapon.shoot(camera, self, current_gun_ammo)
		await get_tree().create_timer(current_weapon.shot_duration).timeout  # Add a small delay to re-enable shooting
		can_shoot = true
		
		if current_weapon.is_full_auto:
			shoot_hold_time += delta
			if current_weapon.is_beam and current_beam:
				current_beam.update_beam(weapon_position.global_position, last_ray_end)
	
	if Input.is_action_pressed("shoot") and current_weapon.is_beam and not current_beam and $ReloadDelay.is_stopped():
		current_weapon.create_beam(self)
		pass
	
	if current_weapon.is_beam and current_gun_ammo < current_weapon.max_ammo and $ReloadDelay.is_stopped():
		current_gun_ammo += current_weapon.recharge_rate * delta
			
	if Input.is_action_just_released("shoot"):
		shoot_hold_time = 0.0
		if current_weapon.is_beam:
			current_weapon.destroy_beam(self)
		
	if ((Input.is_action_just_pressed("reload") and not current_weapon.is_beam) \
	 or current_gun_ammo <= 0)  \
	 and $ReloadDelay.is_stopped():
		$ReloadDelay.start(current_weapon.reload_duration)
		shoot_hold_time = 0.0
		if current_weapon.is_beam:
			current_weapon.destroy_beam(self)
	
	var weapon_count = weapon_inventory.weapon_list.size()
	if Input.is_action_just_pressed("scroll_up"):
		current_weapon = weapon_inventory.weapon_list[(weapon_inventory.weapon_list.find(current_weapon) + 1) % weapon_count]
		current_gun_ammo = current_weapon.max_ammo
		$UI.scroll_weapon_ui()
	elif Input.is_action_just_pressed("scroll_down"):
		current_weapon = weapon_inventory.weapon_list[(weapon_inventory.weapon_list.find(current_weapon) - 1) % weapon_count]
		current_gun_ammo = current_weapon.max_ammo
		$UI.scroll_weapon_ui()
		
func _input(event):
	if event is InputEventMouseMotion and not $UI.is_paused:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY * 0.01)
		camera.rotation.x += -event.relative.y * MOUSE_SENSITIVITY * 0.01
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _on_reload_delay_timeout() -> void:
	current_gun_ammo = current_weapon.max_ammo

func movemement(delta:float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# Get the input direction and handle movement
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	camera.rotation += camera_recoil_offset
