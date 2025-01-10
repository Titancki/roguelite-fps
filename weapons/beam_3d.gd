extends Node3D

@onready var start_position = Vector3.ZERO
@onready var end_position = Vector3.ZERO

func update_beam(start_position: Vector3, end_position: Vector3):
	# Convert positions to the beam's local space to avoid over-rotation issues
	var local_start = to_local(start_position)
	var local_end = to_local(end_position)

	# Update the curve's points
	$Path3D.curve.set_point_position(0, local_start)
	$Path3D.curve.set_point_position(1, local_end)
