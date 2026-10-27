extends CharacterBody2D
@onready var animation: AnimatedSprite2D = $AgentAnimator/AnimatedSprite2D
@onready var climb_cast: RayCast2D = $climb_cast


const SPEED = 100.0
const JUMP_VELOCITY = -200.0
const MAX_HEIGHT = 1000


func _physics_process(delta: float) -> void:
	
	var climbing = climb_cast.get_collider()
	if climbing: _climb_handler(delta)
	else: _movement(delta)
	
	_set_animation()
	move_and_slide()
	
func _climb_handler(delta) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if direction: velocity = direction*SPEED/2
	else: velocity = Vector2.ZERO
	


func _movement(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
func _set_animation() -> void:
	if velocity.x > 0: animation.flip_h = false
	elif velocity.x < 0: animation.flip_h = true
	
	
