extends CharacterBody2D

@export var detection_radius: float = 300.0      # Distance within which the enemy detects the player
@export var chase_speed: float = 150.0             # Horizontal speed when chasing
@export var RUN_PARTICLE_INTERVAL: float = 0.1     # Time interval between run particles
@export var health: int = 100                      # Default health for all enemies
@export var knockback_force: float = 300.0         # Knockback force applied when taking damage
@export var attack_range: float = 50.0             # Distance at which the enemy will attack the player
@export var attack_damage: int = 20                # How much damage the enemy deals per attack
@export var attack_cooldown: float = 1.0           # Time between attacks

@export var run_particles_scene: PackedScene       # Scene for run particles
@export var jump_particles_scene: PackedScene      # Scene for jump particles
@export var fall_particles_scene: PackedScene      # Scene for fall particles

enum State {
	IDLE,
	CHASING
}
var state: int = State.IDLE
var run_particle_timer: float = 0.0               # Timer for run particle effect
var is_taking_damage: bool = false                # Blocks normal behavior when true
var is_attacking: bool = false                    # Prevents overlapping attack actions
var player: Node2D = null
var is_jumping: bool = false
var jump_velocity: float = -400.0          # Upward velocity when jumping
var jump_threshold: float = 50.0           # How much higher the player must be to trigger a jump

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Look for the player by group (make sure your player is in the "Player" group)
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
	# If we're taking damage, skip state-based animation and movement updates.
	if is_taking_damage:
		move_and_slide()
		return

	# Check the distance to the player.
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= detection_radius:
			# If the player is within range and we're idle.
			if state == State.IDLE:
				state = State.CHASING
		else:
			state = State.IDLE

	# Execute behavior based on current state.
	match state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASING:
			_chasing_behavior(delta)
	
	# Always call move_and_slide() so gravity and collisions are applied.
	move_and_slide()

	# Check for attack conditions when chasing.
	if state == State.CHASING and player and not is_attacking:
		# Use the attack range to see if the enemy should attack.
		if global_position.distance_to(player.global_position) <= attack_range:
			attack()

func _idle_behavior(delta: float) -> void:
	sprite.play("idle")
	velocity.x = 0

func _chasing_behavior(delta: float) -> void:
	# If currently attacking, you might want to stop chase movement.
	if is_attacking:
		velocity.x = 0
		return

	sprite.play("run")
	# Compute horizontal direction toward the player.
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity.x = direction.x * chase_speed
	# Flip the sprite based on movement direction.
	sprite.flip_h = velocity.x < 0

	# Create run particles at fixed intervals.
	run_particle_timer += delta
	if run_particle_timer >= RUN_PARTICLE_INTERVAL:
		run_particle_timer = 0
		if run_particles_scene:
			var rp: AnimatedSprite2D = run_particles_scene.instantiate()
			rp.global_position = global_position
			get_parent().add_child(rp)
			rp.flip_h = sprite.flip_h
			rp.play("run")  # Plays run effects.

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
		var jp: AnimatedSprite2D = jump_particles_scene.instantiate()
		jp.global_position = global_position
		get_parent().add_child(jp)
		jp.play("jump")  # Plays jump effects.
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
		var fp: AnimatedSprite2D = fall_particles_scene.instantiate()
		fp.global_position = global_position
		get_parent().add_child(fp)
		fp.play("fall")  # Plays fall effects.
	await sprite.animation_finished
	is_jumping = false
	sprite.play("idle")

# NEW: Attack behavior function.
# This function stops the enemy, plays the attack animation,
# waits a short time for the "hit" to register, and then calls
# the player's apply_damage() function.
@onready var attack_timer: Timer = Timer.new()  # For handling attack cooldown (if you prefer a Timer node, you can also add one in the scene)

func attack() -> void:
	# Mark that an attack is in progress.
	is_attacking = true
	# Stop horizontal movement during the attack.
	velocity = Vector2.ZERO
	# Play the attack animation.
	sprite.play("attack")
	# Optionally, you can wait a short delay before applying damage.
	# This delay can represent the time when the attack "connects."
	await get_tree().create_timer(0.2)
	# Call the player's damage function.
	if player and global_position.distance_to(player.global_position) <= attack_range:
		# It is assumed that the player node has an apply_damage(int) function.
		player.apply_damage(attack_damage)
	# Wait until the attack animation finishes.
	await sprite.animation_finished
	# Optionally, add an attack cooldown so the enemy can’t attack continuously.
	await get_tree().create_timer(attack_cooldown)
	is_attacking = false

# Called when the enemy is hit by a bomb.
func apply_damage(amount: int) -> void:
	if is_taking_damage:
		return

	health -= amount
	print("Enemy took damage:", amount, "Remaining health:", health)
	is_taking_damage = true

	var raw_direction = Vector2(1, -1.5) if sprite.flip_h else Vector2(-1, -1.5)
	var knockback_direction: Vector2 = raw_direction.normalized()
	velocity = knockback_direction * knockback_force
	# Check if health has dropped to or below zero.
	if health > 0:
		# Play the "hit" animation.
		sprite.play("hit")
		await sprite.animation_finished # Wait until the hit animation finishes.
		is_taking_damage = false
		# After finishing hit animation, if the player is still on the ground, revert to idle.
		if is_on_floor():
			sprite.play("idle")
	else:
		# Health is 0 or below: play the "dead_hit" animation and then process death.
		sprite.play("dead_hit")
		await sprite.animation_finished
		die()

func die() -> void:
	print("Enemy died!")
	queue_free()
