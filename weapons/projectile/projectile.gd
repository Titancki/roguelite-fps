class_name Projectile
extends Node3D

var projectile_lifetime: float
var projectile_speed: float
var direction: Vector3 = Vector3.ZERO
var lifetime_timer: float = 0.0

func _ready() -> void:
	set_as_top_level(true)

func _process(delta: float) -> void:
	global_transform.origin += direction * projectile_speed * delta
	lifetime_timer += delta
	if lifetime_timer >= projectile_lifetime:
		queue_free()  # Remove the projectile when its lifetime ends


func _on_area_3d_body_entered(_body: Node3D) -> void:
	queue_free()
