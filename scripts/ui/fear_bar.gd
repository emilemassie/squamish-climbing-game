extends TextureProgressBar
@onready var player: CharacterBody2D = $"../../Player"
@onready var fear_bar: TextureProgressBar = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(player.MAX_HEIGHT, player.position.y)
	var fear_percent = abs(player.position.y)/player.MAX_HEIGHT*100
	fear_bar.set_value_no_signal(fear_percent)
	
	pass
