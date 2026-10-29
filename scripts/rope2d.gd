extends Node2D

@export var ropeLength: float = 30.0
@export var constrain: float = 1.0    # distance between points
@export var gravity: Vector2 = Vector2(0, 9.8)
@export var dampening: float = 0.9
@export var startPin: bool = true
@export var endPin: bool = true

@onready var line2D: Line2D = $Line2D

var pos: PackedVector2Array
var posPrev: PackedVector2Array
var pointCount: int

func _ready() -> void:
	pointCount = get_pointCount(ropeLength)
	resize_arrays()
	init_position()

func get_pointCount(distance: float) -> int:
	return int(ceil(distance / constrain))

func resize_arrays() -> void:
	pos.resize(pointCount)
	posPrev.resize(pointCount)

func init_position() -> void:
	for i in range(pointCount):
		pos[i] = position + Vector2(constrain * i, 0)
		posPrev[i] = position + Vector2(constrain * i, 0)
	position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("click"):     # Move start point
			set_start(get_global_mouse_position())
		if Input.is_action_pressed("right_click"): # Move end point
			set_last(get_global_mouse_position())
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			set_start(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			set_last(get_global_mouse_position())

func _process(delta: float) -> void:
	update_points(delta)
	update_constrain()
	
	# update_constrain() # Repeat to get tighter rope
	# update_constrain()
	
	# Send positions to Line2D for drawing
	line2D.points = pos

func set_start(p: Vector2) -> void:
	pos[0] = p
	posPrev[0] = p

func set_last(p: Vector2) -> void:
	pos[pointCount - 1] = p
	posPrev[pointCount - 1] = p

func update_points(delta: float) -> void:
	for i in range(pointCount):
		# not first and last || first if not pinned || last if not pinned
		if (i != 0 and i != pointCount - 1) or (i == 0 and not startPin) or (i == pointCount - 1 and not endPin):
			var velocity = (pos[i] - posPrev[i]) * dampening
			posPrev[i] = pos[i]
			pos[i] += velocity + (gravity * delta)

func update_constrain() -> void:
	for i in range(pointCount):
		if i == pointCount - 1:
			return
		var distance = pos[i].distance_to(pos[i + 1])
		
		# Prevent division by zero if two points occupy the exact same position
		if distance == 0.0:
			continue
			
		var difference = constrain - distance
		var percent = difference / distance
		var vec2 = pos[i + 1] - pos[i]
		
		# if first point
		if i == 0:
			if startPin:
				pos[i + 1] += vec2 * percent
			else:
				pos[i] -= vec2 * (percent / 2)
				pos[i + 1] += vec2 * (percent / 2)
		# if last point, skip because no more points after it
		elif i == pointCount - 1:
			pass
		# all the rest
		else:
			if i + 1 == pointCount - 1 and endPin:
				pos[i] -= vec2 * percent
			else:
				pos[i] -= vec2 * (percent / 2)
				pos[i + 1] += vec2 * (percent / 2)
