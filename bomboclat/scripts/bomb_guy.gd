extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D  # Player sprite
@onready var run_particles := $RunParticles  # Dust animation for running
@onready var bomb_scene := preload("res://scenes/bomb.tscn")  # Bomb scene
@onready var jump_particles_scene := preload("res://scenes/effects/jumpParticles.tscn")  # Jump effect scene
@onready var fall_particles_scene := preload("res://scenes/effects/fallParticles.tscn")  # Fall effect scene

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var jump_position : Vector2 = Vector2.ZERO  # Position where the player jumps from
var was_in_air = false  # Track if the player was in mid-air

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		was_in_air = true  # The player is now in the air

	# Handle jump (Spacebar & W)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")

		# Store jump position and create a jump effect node at that position
		jump_position = global_position
		var jump_effect = jump_particles_scene.instantiate()
		jump_effect.global_position = jump_position  # Set the effect at the jump position
		get_parent().add_child(jump_effect)  # Add effect to the world
		jump_effect.play("jump")  # Play animation

		was_in_air = true  # The player is now airborne

	# Get input direction for movement (Arrow Keys & A/D)
	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():  # Only play run animation if on the ground
			sprite.play("run")
			run_particles.play("run")  # Play dust animation
			run_particles.visible = true  # Make sure it's visible

			# Flip dust animation and move it behind the player
			run_particles.flip_h = direction < 0
			run_particles.position.x = 15 if direction < 0 else -15
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			sprite.play("idle")  # Play idle animation when not moving
			run_particles.stop()
			run_particles.visible = false  # Hide when not running or jumping
			
	# Handle landing effect
	if is_on_floor() and was_in_air:
		was_in_air = false  # Player has landed

		# Spawn fall effect at landing position
		var fall_effect = fall_particles_scene.instantiate()
		fall_effect.global_position = global_position
		get_parent().add_child(fall_effect)  # Add effect to the world
		fall_effect.play("fall")  # Play fall effect

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
