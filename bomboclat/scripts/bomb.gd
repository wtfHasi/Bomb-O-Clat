extends RigidBody2D  # Use RigidBody2D for realistic bomb physics

@onready var sprite := $AnimatedSprite2D
@onready var timer := $Timer  # If using a timer

const EXPLOSION_DELAY = 2.0  # Adjust as needed

func _ready():
	sprite.play("on")  # Start with the active bomb animation
	timer.start(EXPLOSION_DELAY)  # Start countdown

func _on_timer_timeout() -> void:
	explode()

func explode():
	sprite.play("explosion")
	# Add explosion effect, damage logic, etc.
	await sprite.animation_finished  # Wait for animation to end
	queue_free()  # Remove bomb from scene
