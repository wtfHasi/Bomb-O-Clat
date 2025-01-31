extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D  # Reference AnimatedSprite2D
@onready var particles := $RunParticles  # Reference the second AnimatedSprite2D
@onready var bomb_scene := preload("res://scenes/bomb.tscn")  # Load bomb scene

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		# Play jump animation if in air
		sprite.play("jump")

	# Handle jump (Spacebar & W)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")

	# Get input direction for movement (Arrow Keys & A/D)
	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():  # Only play run animation if on the ground
			sprite.play("run")
			particles.play("dust")  # Play dust animation
			particles.visible = true  # Make sure it's visible
		# Flip character based on direction
		# Flip the dust animation and move it behind
			particles.flip_h = direction < 0
			particles.position.x = 15 if direction < 0 else -15
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			sprite.play("idle")  # Play idle animation when not moving
			particles.stop()
			particles.visible = false  # Hide when not running

	move_and_slide()
	
func throw_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = position  # Start from BombGuy's position
	bomb.apply_impulse(Vector2(200 * (1 if not sprite.flip_h else -1), -200))  # Throw forward
	get_parent().add_child(bomb)  # Add bomb to scene

func _input(event):
	if event.is_action_pressed("throw_bomb"):
		throw_bomb()
