extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D  # Player sprite
@onready var particles := $Particles  # Dust particles AnimatedSprite2D
@onready var bomb_scene := preload("res://scenes/bomb.tscn")  # Bomb scene

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

		# Handle jump and fall animations
		if velocity.y < 0:  # Jumping
			particles.play("jump")  # Play jump particle animation
			particles.visible = true
			particles.position = Vector2(0, -5)  # Set to bottom center
		elif velocity.y > 0:  # Falling
			particles.play("fall")  # Play fall particle animation
			particles.visible = true
			particles.position = Vector2(0, -5)  # Set to bottom center

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

			# Flip dust animation and move it behind the player
			particles.flip_h = direction < 0
			particles.position.x = 15 if direction < 0 else -15
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			sprite.play("idle")  # Play idle animation when not moving
			particles.stop()
			particles.visible = false  # Hide when not running or jumping

	move_and_slide()

# Throw bomb function
func throw_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = position  # Spawn at BombGuy's position
	get_parent().add_child(bomb)  # Add bomb to scene

	# Ensure bomb is RigidBody2D and apply force
	if bomb is RigidBody2D:
		var throw_direction = Vector2(200 * (1 if not sprite.flip_h else -1), -200)
		bomb.apply_force(throw_direction)  # Use apply_force() in Godot 4

# Input handling for throwing bomb
func _input(event):
	if event.is_action_pressed("throw_bomb"):
		throw_bomb()
