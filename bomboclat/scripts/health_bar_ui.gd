extends Control

@onready var hearts = [
	$HealthBarBG/Heart1,
	$HealthBarBG/Heart2,
	$HealthBarBG/Heart3
]

func _ready() -> void:
	# Look for nodes in the "player" group.
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		player.health_changed.connect(Callable(self, "update_health"))
		update_health(player.health)  # Initialize the health bar with current health.
	else:
		push_error("No player found in group 'player'!")

func update_health(current_health: int) -> void:
	var hearts_to_show = int(ceil(float(current_health) / 50.0))
	for i in range(hearts.size()):
		hearts[i].visible = i < hearts_to_show
