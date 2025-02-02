extends CharacterBody2D

@export var detection_radius: float = 300.0      # Distance within which the enemy detects the player
@export var chase_speed: float = 150.0             # Horizontal speed when chasing
@export var jump_velocity: float = -400.0          # Upward velocity when jumping
@export var jump_threshold: float = 50.0           # How much higher the player must be to trigger a jump

@export var alert_scene: PackedScene               # The scene for the alert effect
@export var run_particles_scene: PackedScene       # Scene for run particles
@export var jump_particles_scene: PackedScene      # Scene for jump particles
@export var fall_particles_scene: PackedScene      # Scene for fall particles

enum State {
	IDLE,
	ALERTED,
	CHASING
}
var state: int = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var is_jumping: bool = false

func _ready() -> void:
	# Look for the player by group. Make sure your player node is added to the "Player" group.
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		print("No player found in group 'Player'.")
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	# Always apply gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Check the distance to the player.
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= detection_radius:
			# If the player is within range and we're idle, switch to ALERTED.
			if state == State.IDLE:
				state = State.ALERTED
				_alert_behavior()  # This function will await the alert scene.
			else:
				state = State.CHASING
		else:
			state = State.IDLE

	# Execute behavior based on current state.
	match state:
		State.IDLE:
			_idle_behavior(delta)
		State.ALERTED:
			# The ALERTED state is handled inside _alert_behavior()
			pass
		State.CHASING:
			_chasing_behavior(delta)
	
	# Always call move_and_slide() so gravity and collisions are applied.
	move_and_slide()

func _idle_behavior(delta: float) -> void:
	sprite.play("idle")
	velocity.x = 0

func _alert_behavior() -> void:
	# Instantiate the alert scene above the enemy.
	if alert_scene:
		var alert_instance = alert_scene.instantiate()
		# Adjust the offset as needed (here, 50 pixels above)
		alert_instance.position = global_position + Vector2(0, -50)
		get_parent().add_child(alert_instance)
		# Await the alert scene's completion signal.
		await alert_instance.alert_finished
	# After the alert finishes, switch to chasing.
	state = State.CHASING

func _chasing_behavior(delta: float) -> void:
	sprite.play("run")
	# Compute horizontal direction toward the player.
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity.x = direction.x * chase_speed
	# Flip the sprite based on movement direction.
	sprite.flip_h = velocity.x < 0

	# If the player is above the enemy by jump_threshold and the enemy is on the floor, jump.
	if is_on_floor() and not is_jumping:
		if player.global_position.y < global_position.y - jump_threshold:
			await _start_jump_sequence()

func _start_jump_sequence() -> void:
	is_jumping = true
	# Play jump anticipation animation.
	sprite.play("jump_anticipation")
	await sprite.animation_finished

	# Apply jump force.
	velocity.y = jump_velocity
	sprite.play("jump")
	# Instantiate jump particles, if available.
	if jump_particles_scene:
		var jp = jump_particles_scene.instantiate()
		jp.global_position = global_position
		get_parent().add_child(jp)
		if jp.has_method("play"):
			jp.play("jump")
	# Small delay to allow the jump to register.
	await get_tree().create_timer(0.1).timeout
	# While in the air, if falling, play the fall animation.
	while not is_on_floor():
		if velocity.y > 0 and sprite.animation != "fall":
			sprite.play("fall")
		await get_tree().create_timer(0.01).timeout

	# Upon landing, play ground animation and instantiate fall particles.
	sprite.play("ground")
	if fall_particles_scene:
		var fp = fall_particles_scene.instantiate()
		fp.global_position = global_position
		get_parent().add_child(fp)
		if fp.has_method("play"):
			fp.play("fall")
	await sprite.animation_finished
	is_jumping = false
	sprite.play("idle")
