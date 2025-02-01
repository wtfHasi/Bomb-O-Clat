extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D  # Player sprite
@onready var bomb_scene := preload("res://scenes/objects/bomb.tscn")  # Bomb scene
@onready var run_particles_scene := preload("res://scenes/effects/runParticles.tscn")  # Run effect scene
@onready var jump_particles_scene := preload("res://scenes/effects/jumpParticles.tscn")  # Jump effect scene
@onready var fall_particles_scene := preload("res://scenes/effects/fallParticles.tscn")  # Fall effect scene

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const RUN_PARTICLE_INTERVAL = 0.1  # Delay between spawning run particles

var jump_position : Vector2 = Vector2.ZERO  # Position where the player jumps from
var was_in_air = false  # Track if the player was in mid-air
var run_particle_timer = 0.0  # Timer for run particle effect
var is_jumping = false  # Prevent multiple jumps during anticipation

func _physics_process(delta: float) -> void:
	# Apply gravity when not on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
		was_in_air = true

	# Detect falling motion (after reaching peak) and play "fall" animation if needed
	if velocity.y > 0 and was_in_air and sprite.animation != "fall":
		sprite.play("fall")

	# Handle jump input (only if on the ground and not already in a jump sequence)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jumping:
		start_jump_sequence()
	
	# Movement logic (left/right)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor() and not is_jumping:
			sprite.play("run")
			
			# Create run particles at intervals
			run_particle_timer += delta
			if run_particle_timer >= RUN_PARTICLE_INTERVAL:
				run_particle_timer = 0
				var run_effect = run_particles_scene.instantiate()
				run_effect.global_position = global_position
				get_parent().add_child(run_effect)
				run_effect.flip_h = direction < 0
				run_effect.play("run")
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not is_jumping:
			sprite.play("idle")

	# Handle landing effect
	if is_on_floor() and was_in_air:
		was_in_air = false  # The player has landed
		# Play ground animation, wait for it to finish, then spawn the fall effect.
		sprite.play("ground")
		var fall_effect = fall_particles_scene.instantiate()
		fall_effect.global_position = global_position
		get_parent().add_child(fall_effect)
		fall_effect.play("fall")
		await sprite.animation_finished
		sprite.play("idle")

	move_and_slide()

func start_jump_sequence() -> void:
	is_jumping = true
	sprite.play("jump_anticipation")
	# Wait for the anticipation animation to finish without blocking the main loop
	await sprite.animation_finished

	# Now apply jump force and switch to jump animation
	velocity.y = JUMP_VELOCITY
	sprite.play("jump")
	
	# Spawn jump effect
	jump_position = global_position
	var jump_effect = jump_particles_scene.instantiate()
	jump_effect.global_position = jump_position
	get_parent().add_child(jump_effect)
	jump_effect.play("jump")
	
	is_jumping = false  # Allow another jump after this sequence

# Throw bomb function
func throw_bomb() -> void:
	var bomb = bomb_scene.instantiate()
	bomb.position = position  # Spawn at BombGuy's position
	get_parent().add_child(bomb)
	
	# If bomb is a RigidBody2D, apply force to it
	if bomb is RigidBody2D:
		var throw_direction = Vector2(200 * (1 if not sprite.flip_h else -1), -200)
		bomb.apply_force(throw_direction)

# Input handling for throwing bomb
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("throw_bomb"):
		throw_bomb()
