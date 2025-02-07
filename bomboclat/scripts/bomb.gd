extends RigidBody2D

@onready var sprite := $AnimatedSprite2D
@onready var timer := $Timer

const EXPLOSION_DELAY = 2.0  # Time (in seconds) before the bomb explodes
@export var damage = 50                    # Damage dealt by the bomb
@export var explosion_radius = 100.0       # Explosion detection radius (adjust as needed)
@export var explosion_strength = 300.0    # The base impulse force magnitude

func _ready() -> void:
	sprite.play("on")                # Play the active bomb animation
	timer.start(EXPLOSION_DELAY)     # Start the countdown

func _on_timer_timeout() -> void:
	explode()

func explode() -> void:
	sprite.play("explosion")
	
	var space_state = get_world_2d().direct_space_state
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var result = space_state.intersect_shape(query)
	print("Explosion query hit ", result.size(), " objects.")
	
	for item in result:
		var collider = item.collider
		print("Detected collider: ", collider.name)
		
		# If the collider has an apply_damage method, invoke it.
		if collider.has_method("apply_damage"):
			collider.apply_damage(damage)
		
		# If the collider has the method to apply the explosion impulse, call it.
		if collider.has_method("apply_explosion_impulse"):
			collider.apply_explosion_impulse(global_position, explosion_strength)
			print("Applied explosion impulse to: ", collider.name)
			
	await sprite.animation_finished
	queue_free()
