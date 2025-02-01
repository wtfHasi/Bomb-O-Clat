extends RigidBody2D

@onready var sprite := $AnimatedSprite2D
@onready var timer := $Timer

const EXPLOSION_DELAY = 2.0  # Time (in seconds) before the bomb explodes
@export var damage = 50              # Damage dealt by the bomb
@export var explosion_radius = 100.0 # Explosion detection radius (adjust as needed)

func _ready() -> void:
	sprite.play("on")           # Play the active bomb animation
	timer.start(EXPLOSION_DELAY)  # Start the countdown

func _on_timer_timeout() -> void:
	explode()

func explode() -> void:
	# Play the explosion animation
	sprite.play("explosion")
	
	# Use the physics engine to detect bodies within the explosion radius.
	var space_state = get_world_2d().direct_space_state

	# Create a temporary circle shape to represent the explosion area.
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius

	# Set up the query parameters using the bomb's global position.
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	# Perform the query.
	var result = space_state.intersect_shape(query)
	for item in result:
		var collider = item.collider
		if collider.has_method("apply_damage"):
			collider.apply_damage(damage)
	
	# Wait for the explosion animation to finish before cleaning up.
	await sprite.animation_finished
	queue_free()
