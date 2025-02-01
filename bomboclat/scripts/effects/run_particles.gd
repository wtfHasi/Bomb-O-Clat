extends AnimatedSprite2D

func _ready():
	animation_finished.connect(_on_animation_finished)  # Connect animation_finished signal

func _on_animation_finished():
	queue_free()  # Remove this node after animation finishes
