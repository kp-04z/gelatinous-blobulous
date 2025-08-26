extends CharacterBody2D

const tile_size = 32
var moving = false
var speed = 10
var forced_direction: Vector2 = Vector2.ZERO
var sliding_on_ice: bool = false

@onready var sprite = $Sprite2D
@onready var ray = $RayCast2D
@onready var conveyor_up: TileMapLayer = $"../conveyor_up"
@onready var conveyor_down: TileMapLayer = $"../conveyor_down"
@onready var conveyor_left: TileMapLayer = $"../conveyor_left"
@onready var conveyor_right: TileMapLayer = $"../conveyor_right"
@onready var ice: TileMapLayer = $"../ice"

var inputs = {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN
}

var animation_lookup_table_example = {
	"right": true,
	"left": false,
	"up": null,
	"down": null
}

func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size / 2
	
func get_key_from_vector(vec: Vector2) -> String:
	for k in inputs.keys():
		if inputs[k] == vec:
			return k
	return ""
	
func is_on_ice() -> bool:
	var cell = ice.local_to_map(position)
	return ice.get_cell_source_id(cell) != -1
	
func get_conveyor_direction() -> Vector2:
	var cell = conveyor_down.local_to_map(position)

	if conveyor_up.get_cell_source_id(cell) != -1:
		return Vector2.UP
	if conveyor_down.get_cell_source_id(cell) != -1:
		return Vector2.DOWN
	if conveyor_left.get_cell_source_id(cell) != -1:
		return Vector2.LEFT
	if conveyor_right.get_cell_source_id(cell) != -1:
		return Vector2.RIGHT
		
	return Vector2.ZERO

			
func _physics_process(delta: float) -> void:
	if moving:
		return

	var conveyor_direction = get_conveyor_direction()
	if conveyor_direction != Vector2.ZERO:
		sliding_on_ice = false
		forced_direction = conveyor_direction
		animate(get_key_from_vector(forced_direction))
		move(get_key_from_vector(forced_direction))
		return

	if sliding_on_ice:
		# keep sliding until not on ice
		if is_on_ice():
			move(get_key_from_vector(forced_direction))
			return
		else:
			sliding_on_ice = false
			forced_direction = Vector2.ZERO

	# Otherwise: player input
	for direction in inputs.keys():
		if Input.is_action_just_pressed(direction):
			forced_direction = inputs[direction]  
			move(direction)
			if is_on_ice():
				sliding_on_ice = true
			return

	move_and_slide()

func move(direction):
	if moving == false:
		ray.target_position = inputs[direction] * tile_size
		ray.force_raycast_update()

		if !ray.is_colliding(): # checks if front of character is passable or impassable
			moving = true
			
			var tween = create_tween()
			tween.tween_property(
				self, # who/what it affects
				'position', # property name
				position + inputs[direction] * tile_size, # end position
				0.25 # duration
			)
			tween.tween_callback(move_false)

func move_false():
	moving = false
	
	if is_on_ice():
		sliding_on_ice = true
		if forced_direction != Vector2.ZERO:
			move(get_key_from_vector(forced_direction))

func animate(direction):
	# use dir ("left", "right", "up", "down")
	# to animate an animation tree based on dir's value
	
	# change lookup table name, placeholder variable name only (delete this comment)
	var boolean = animation_lookup_table_example[direction]
	if boolean != null:
		sprite.flip_h = boolean
	
