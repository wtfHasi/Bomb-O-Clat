extends RigidBody2D

# This function applies an explosion impulse to the prop.
# is calculated and multiplied by a force magnitude.
func apply_explosion_impulse(explosion_origin: Vector2, explosion_force: float) -> void:
	var diff = global_position - explosion_origin
	if diff == Vector2.ZERO:
		return
	
	var impulse_direction = diff.normalized()
	
	apply_central_impulse(impulse_direction * explosion_force)  # Apply force
	print("Applied explosion impulse:", impulse_direction * explosion_force, " to ", name)
