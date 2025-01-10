class_name WeaponResource
extends Resource

@export var name: String = "Weapon"
@export var range: float = 10.0  # Maximum range for hitscan
@export var damage: int = 10  # Damage dealt by this weapon
@export var recoil_strength : float = 10.0
@export var recoil_duration : float = 0.4
@export var reload_duration: float = 0.5  # Time between shots
@export var max_ammo : int = 6
@export var shot_duration : float = 0.05
@export var hit_effect: PackedScene = null  # Optional effect for hit

@export_category("Melee weapons")
@export var is_melee: bool = false

@export_category("Projectile weapons")
@export var is_projectile: bool = false
@export var projectile_scene: PackedScene
@export var projectile_lifetime: float = 0.5
@export var projectile_speed: float = 10.0

@export_category("Beam weapons")
@export var is_beam: bool = false
@export var recharge_rate : int = 0

@export_category("Hitscan weapons")
@export var is_full_auto: bool = false
@export var spread_strength : float = 0.0
@export var spread_speed: float = 5.0

@export_category("Weapon textures")
@export var decal_texture: Texture2D = null  # Optional decal for hit
@export var decal_size: float = 0.05
@export var hit_sound: AudioStream = null  # Optional sound for hit



func shoot(camera: Camera3D, player: Node, ammo: int) -> int:
	var direction = -camera.global_transform.basis.z
	
	if is_projectile and projectile_scene:
		var projectile = projectile_scene.instantiate()
		player.add_child(projectile)
		projectile.projectile_lifetime = projectile_lifetime
		projectile.projectile_speed = projectile_speed
		projectile.direction = direction
		projectile.global_position = player.weapon_position.global_position
		
	else:
		var ray_start = camera.global_transform.origin
		if spread_strength > 0 and is_full_auto:
			var hold_multiplier = clamp(player.shoot_hold_time, 0, 1) * spread_speed
			var spread = deg_to_rad(spread_strength * hold_multiplier)
			direction = direction.rotated(Vector3.UP, randf_range(-spread, spread))
			direction = direction.rotated(Vector3.RIGHT, randf_range(-spread, spread))

		# Calculate the ray end point with spread
		var ray_end = ray_start + (direction * range)
		player.last_ray_end = ray_end
		var query = PhysicsRayQueryParameters3D.new()
		query.collision_mask = 1  # Replace with the appropriate layer mask
		query.from = ray_start
		query.to = ray_end
		var space_state = player.get_world_3d().direct_space_state
		var ray_result = space_state.intersect_ray(query)

		if hit_sound:
			var audio_player = AudioStreamPlayer3D.new()
			audio_player.stream = hit_sound
			player.add_child(audio_player)
			audio_player.global_transform.origin = player.global_transform.origin
			audio_player.play()
			audio_player.connect("finished", audio_player.queue_free)

		if ray_result:
			var hit_position = ray_result.position
			player.last_ray_end = hit_position
			var hit_normal = ray_result.normal
			var hit_collider = ray_result.collider
			if decal_texture:
				var decal = Decal.new()
				decal.texture_albedo = decal_texture
				if hit_collider:
					hit_collider.add_child(decal)
					decal.global_transform.origin = hit_position
					var decal_basis = Basis()
					decal_basis.z = -hit_normal.normalized()
					decal_basis.y = Vector3.UP if abs(hit_normal.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
					decal_basis.x = decal_basis.y.cross(decal_basis.z).normalized()
					decal_basis.y = decal_basis.z.cross(decal_basis.x).normalized()
					decal.global_transform.basis = decal_basis
					decal.global_transform.basis *= Basis(Vector3(1, 0, 0), deg_to_rad(90))
					var alignment_factor = abs(hit_normal.dot(Vector3.UP))
					decal.extents = Vector3(decal_size, decal_size, decal_size) * (1.0 + alignment_factor)
					call_deferred("remove_decal_after_time", decal, 60.0, player)

			if hit_effect:
				var effect = hit_effect.instantiate()
				effect.global_transform.origin = hit_position
				player.add_child(effect)

	apply_recoil(camera, player)
		
	return ammo - 1
	
func apply_recoil(camera, player):
	# Create a tween for the camera
	var tween = camera.create_tween()
	# Smoothly interpolate the X component of the rotation
	tween.tween_property(
		player,
		"camera_recoil_offset:x",  # Target the x component specifically
		deg_to_rad(recoil_strength),
		recoil_duration / 2
	)
	tween.tween_property(
		player,
		"camera_recoil_offset",  # Target the x component specifically
		Vector3.ZERO,
		recoil_duration / 2
	)


func create_beam(player):
	player.current_beam = preload("res://weapons/beam_3d.tscn").instantiate()  # Load the beam scene
	player.add_child(player.current_beam)  # Add the beam to the scene

func destroy_beam(player):
	if player.current_beam:
		player.current_beam.queue_free()
		player.current_beam = null

func remove_decal_after_time(decal: Node, delay: float, player) -> void:
	await player.get_tree().create_timer(delay).timeout
	if decal and decal.is_inside_tree():
		decal.queue_free()
