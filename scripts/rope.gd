extends Node2D

#@export var segment_length_target: float = 12.0 # INCREASED: 12-20px prevents solver overload     # Collision radius for circles
@export var softness: float = 0.0               # CHANGED: 0.0 makes joints rigid, preventing stretch
@export var rope_thinkness: int = 4
var segment_thickness = rope_thinkness
var segment_length_target = rope_thinkness*2
@export var anchor_texture: Texture2D
@export var texture: Texture2D
@export var rope_end_texture: Texture2D

@onready var rope_line: Line2D = $rope_line
@onready var anchor: StaticBody2D = $anchor
@onready var end_part: RigidBody2D = $end_part
@onready var anchor_sprite: Sprite2D = $anchor/Anchor
@onready var rope_end_sprite: Sprite2D = $end_part/RopeEnd

var rope_segments: Array[RigidBody2D] = []

func _ready() -> void:
	rope_line.width = int(rope_thinkness)
	anchor_sprite.texture = anchor_texture
	rope_end_sprite.texture = rope_end_texture
	rope_line.texture = texture
	
	# Step 1: Resample original Line2D points for uniform spacing
	var resampled_points: PackedVector2Array = _resample_points(rope_line.points, segment_length_target)
	if resampled_points.size() < 2:
		push_warning("Line2D path is too short to generate rope segments.")
		return

	rope_line.points = resampled_points
	var total_points: int = resampled_points.size()

	# Step 2: Create RigidBody2D segments with CircleShape2D
	for i in range(total_points - 1):
		var p_start: Vector2 = rope_line.to_global(resampled_points[i])
		var p_end: Vector2 = rope_line.to_global(resampled_points[i + 1])
		var segment_center: Vector2 = (p_start + p_end) / 2.0

		var segment = RigidBody2D.new()
		segment.collision_layer = 16
		segment.collision_mask = 16
		
		# Mass, damping, and solver settings for stability
		segment.mass = 0.25
		#segment.linear_damp = 3
		#segment.angular_damp = 2.0
		segment.can_sleep = false # Keeps joint constraint solver active
		
		add_child(segment)
		segment.global_position = segment_center
		segment.rotation = (p_end - p_start).angle()
		segment.add_to_group("rope_segments")
		rope_segments.append(segment)

		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = segment_thickness
		col.shape = shape
		segment.add_child(col)

	# Step 3: Pin joints between anchor, segments, and end_part
	for i in range(total_points):
		var joint_pos: Vector2 = rope_line.to_global(resampled_points[i])
		var joint = PinJoint2D.new()
		
		# Set softness near 0 to remove rubber-band stretching
		joint.softness = softness
		joint.disable_collision = true
		add_child(joint)
		joint.global_position = joint_pos
		joint.add_to_group("rope_joints")

		if i == 0:
			joint.node_a = anchor.get_path()
			joint.node_b = rope_segments[0].get_path()
		elif i == total_points - 1:
			end_part.global_position = joint_pos
			joint.node_a = rope_segments[rope_segments.size() - 1].get_path()
			joint.node_b = end_part.get_path()
		else:
			joint.node_a = rope_segments[i - 1].get_path()
			joint.node_b = rope_segments[i].get_path()
			
	end_part.mass = 0.2
	end_part.linear_damp = 1.5
	end_part.angular_damp = 2.0

func _process(_delta: float) -> void:
	if rope_segments.is_empty():
		return

	# Point 0 locked to anchor
	rope_line.set_point_position(0, rope_line.to_local(anchor.global_position))
	
	# Correctly track segment body positions directly
	for i in range(rope_segments.size()):
		rope_line.set_point_position(i + 1, rope_line.to_local(rope_segments[i].global_position))
		
	# Last point locked to end_part
	rope_line.set_point_position(rope_line.points.size() - 1, rope_line.to_local(end_part.global_position))

# Resamples an array of points using arc-length parameterization
func _resample_points(raw_points: PackedVector2Array, spacing: float) -> PackedVector2Array:
	if raw_points.size() < 2:
		return raw_points

	var new_points: PackedVector2Array = [raw_points[0]]
	var accumulated_dist: float = 0.0

	var i: int = 0
	while i < raw_points.size() - 1:
		var p_start: Vector2 = raw_points[i]
		var p_end: Vector2 = raw_points[i + 1]
		var segment_dist: float = p_start.distance_to(p_end)

		if segment_dist == 0.0:
			i += 1
			continue

		if accumulated_dist + segment_dist >= spacing:
			var remaining: float = spacing - accumulated_dist
			var direction: Vector2 = (p_end - p_start).normalized()
			var next_point: Vector2 = p_start + direction * remaining
			
			new_points.append(next_point)
			raw_points[i] = next_point
			accumulated_dist = 0.0
		else:
			accumulated_dist += segment_dist
			i += 1

	if new_points[new_points.size() - 1].distance_to(raw_points[raw_points.size() - 1]) > spacing * 0.5:
		new_points.append(raw_points[raw_points.size() - 1])
	else:
		new_points[new_points.size() - 1] = raw_points[raw_points.size() - 1]

	return new_points
