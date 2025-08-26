extends CharacterBody2D

const tile_size = 32
var moving = false
var speed = 10

@onready var sprite = $Sprite2D
@onready var ray = $RayCast2D

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

func _physics_process(delta: float) -> void:
	for direction in inputs.keys():
		if Input.is_action_just_pressed(direction):
			animate(direction)
			move(direction)
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

func animate(direction):
	# use dir ("left", "right", "up", "down")
	# to animate an animation tree based on dir's value
	
	# change lookup table name, placeholder variable name only (delete this comment)
	var boolean = animation_lookup_table_example[direction]
	if boolean != null:
		sprite.flip_h = boolean
	
