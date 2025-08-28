extends CharacterBody2D

# initialises variables
const tile_size = 32
var moving = false
var speed = 10

var forced_direction: Vector2 = Vector2.ZERO
var last_direction = "down"
var sliding_on_ice: bool = false
var is_colliding = false
#var can_tp = true

@onready var sprite = $Sprite2D
@onready var ray = $RayCast2D

var inputs = {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN
}

@onready var map: TileMapLayer = $"../grass"
@onready var ice: TileMapLayer = $"../ice"
@onready var oneway: TileMapLayer = $"../oneway"
@onready var conveyors = {
	"right":  $"../conveyor_right",
	"left": $"../conveyor_left",
	"up": $"../conveyor_up",
	"down": $"../conveyor_down"
}


# snaps player to center of tile
func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size / 2


func get_key_from_vector(vector: Vector2) -> String:
	for key in inputs.keys():
		if inputs[key] == vector:
			return key
	return ""


func is_on_ice() -> bool:
	var cell = map.local_to_map(position)
	return ice.get_cell_source_id(cell) != -1


func get_conveyor_direction() -> Vector2:
	var cell = map.local_to_map(position)
	for direction in conveyors.keys():
		if conveyors[direction].get_cell_source_id(cell) != -1:
			return inputs[direction]
	
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	if moving:
		return

	var conveyor_direction = get_conveyor_direction()
	if conveyor_direction != Vector2.ZERO && !is_colliding: # if stepping on a conveyor belt and not colliding
		sliding_on_ice = false
		forced_direction = conveyor_direction
		
		animate(get_key_from_vector(forced_direction))
		move(get_key_from_vector(forced_direction))
		return

	if sliding_on_ice:
		# Keep sliding until not on ice
		if is_on_ice():
			animate(get_key_from_vector(forced_direction))
			move(get_key_from_vector(forced_direction))
			return
		else:
			sliding_on_ice = false
			forced_direction = Vector2.ZERO

	# Otherwise: player input
	for direction in inputs.keys():
		if Input.is_action_pressed(direction):
			forced_direction = inputs[direction] 
			last_direction = direction
			
			if !moving:
				animate(direction)
				move(direction)
			
			if is_on_ice():
				sliding_on_ice = true
			return
	
	move_and_slide()


func move(direction):
	if moving == false:
		ray.target_position = inputs[direction] * tile_size
		ray.force_raycast_update()
		
		var cell = map.local_to_map(position + inputs[direction])
		if !ray.is_colliding() or (ray.is_colliding() and oneway.get_cell_source_id(cell) != -1 and direction=="down"): # checks if front of character is passable or impassable
			moving = true
			is_colliding = false
			
			last_direction = direction
			animate(direction)
			
			var tween = create_tween()
			tween.tween_property(
				self, # who/what it affects
				'position', # property name
				position + inputs[direction] * tile_size, # end position
				0.25 # duration
			)
			tween.tween_callback(move_false)
		else:
			sliding_on_ice = false
			is_colliding = true


func move_false():
	moving = false
	
	if is_on_ice():
		sliding_on_ice = true
		if forced_direction != Vector2.ZERO:
			move(get_key_from_vector(forced_direction))
	else:
		forced_direction == Vector2.ZERO
		
	animate(last_direction)


func animate(last_direction):
	if moving && get_conveyor_direction() == Vector2.ZERO && !is_on_ice():
		sprite.play("move_" + last_direction)
	else:
		sprite.play("idle_" + last_direction)
