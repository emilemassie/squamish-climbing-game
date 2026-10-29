extends Node2D

@export var segment_thickness: float = 2.0 # Collision radius/width for the rope
@export var softness: float = 0.25
@export var rope_end_texture: Texture2D
@export var texture: Texture2D
@export var anchor_texture: Texture2D

@onready var rope_line: Line2D = $rope_line
@onready var anchor: StaticBody2D = $anchor
@onready var end_part: RigidBody2D = $end_part
@onready var anchor_sprite: Sprite2D = $anchor/Anchor
@onready var rope_end_sprite: Sprite2D = $end_part/RopeEnd

var rope_segments: Array[RigidBody2D] = []

func _ready() -> void:
	rope_line.width = int(segment_thickness)
	#rope_line.default_color = Color(0.851, 0.627, 0.4, 1.0) # Bright red for high visibility
	#rope_line.z_index = 100
	
	anchor_sprite.texture = anchor_texture
	rope_end_sprite.texture = rope_end_texture
	rope_line.texture = texture
	
	
	var points = rope_line.points
	var total_points: int = points.size()
	
	if total_points < 2:
		push_warning("Line2D needs at least 2 points to build a rope.")
		return

	# Step 1: Create RigidBody2D segments between each pair of points
	for i in range(total_points - 1):
		var p_start: Vector2 = rope_line.to_global(points[i])
		var p_end: Vector2 = rope_line.to_global(points[i + 1])
		var segment_center: Vector2 = (p_start + p_end) / 2.0
		var segment_vector: Vector2 = p_end - p_start
		var segment_length: float = segment_vector.length()

		# Create RigidBody2D segment using global_position
		var segment = RigidBody2D.new()
		
		segment.collision_layer = 5
		
		segment.mass = 0.05                             # Reduce weight (default is 1.0)
		#segment.gravity_scale = 1.0                     # Keep natural gravity drop
		#segment.linear_damp = 2.0                       # Dampen swinging to prevent aggressive spastic movement
		#segment.angular_damp = 2.0
		#segment.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY # Prevents light fast objects from passing through colliders
				
		
		
		add_child(segment) # Add child FIRST so global_position resolves accurately
		segment.global_position = segment_center
		segment.rotation = segment_vector.angle()
		segment.add_to_group("rope_segments")
		rope_segments.append(segment)

		# Create CapsuleCollisionShape2D for the segment
		var col = CollisionShape2D.new()
		var shape = CapsuleShape2D.new()
		shape.radius = segment_thickness
		shape.height = max(segment_length, segment_thickness * 2.0) # Height must be >= 2 * radius
		col.shape = shape
		col.rotation = Vector2.RIGHT.angle_to(Vector2.DOWN) # Orient capsule along segment
		segment.add_child(col)

	# Step 2: Connect Anchor -> Segments -> End Part using PinJoint2D at every vertex
	for i in range(total_points):
		var joint_pos: Vector2 = rope_line.to_global(points[i])
		var joint = PinJoint2D.new()
		joint.softness = softness
		joint.disable_collision = true
		add_child(joint) # Add child FIRST
		joint.global_position = joint_pos # Use global_position instead of local position
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
			
	end_part.mass = .2
	#end_part.angular_damp = 5

func _process(_delta: float) -> void:
	if rope_segments.size() > 0:
		# Point 0 is pinned to anchor
		rope_line.set_point_position(0, rope_line.to_local(anchor.global_position))
		
		# Intermediate points track joint locations between segments
		for i in range(rope_segments.size() - 1):
			var joint_pos: Vector2 = (rope_segments[i].global_position + rope_segments[i + 1].global_position) / 2.0
			rope_line.set_point_position(i + 1, rope_line.to_local(joint_pos))
			
		# Last point tracks end_part
		rope_line.set_point_position(rope_line.points.size() - 1, rope_line.to_local(end_part.global_position))

	queue_redraw()

#func _draw() -> void:

	# Convert Line2D local positions into this Node2D's local coordinate space
	#for point in rope_line.points:
	#	var global_p: Vector2 = rope_line.to_global(point)
	#	var local_p: Vector2 = to_local(global_p)
	#	draw_circle(local_p, 4.0, Color.GREEN)
