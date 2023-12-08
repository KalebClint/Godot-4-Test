extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var sensetivity = 0.35

var flipping = false
var flipped = false
var wallJumped = false

var slamming = false
var slamRecovering = false
var slamRecoverTime = 2

var canWallJump = false

@onready var spawn = $"../Spawn"

@onready var body = $Body

@onready var camMount = $CameraMount

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	flipping = false


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensetivity))
		body.rotate_y(deg_to_rad(event.relative.x * sensetivity))
		
		camMount.rotate_x(deg_to_rad(-event.relative.y * sensetivity) )
		camMount.rotation.x = clamp(camMount.rotation.x,deg_to_rad(-90),deg_to_rad(45))

func _physics_process(delta):
	
	if position.y < -10:
		position = spawn.position
	
	if !flipping:
		body.rotation.x = 0
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		flipped = false
		wallJumped = false

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") && is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	elif canWallJump && Input.is_action_just_pressed("ui_accept") && !wallJumped && !is_on_floor():
		velocity.y = JUMP_VELOCITY - 1
		canWallJump = false
		flipped = false
		
	elif Input.is_action_just_pressed("ui_accept") && !is_on_floor() && !flipped:
		velocity.y = JUMP_VELOCITY - 3
		flippingIt()
		flipped = true;
		
		
	if Input.is_action_just_pressed("Shift"):
		if is_on_floor():
			slamming = true
			
			velocity.y = JUMP_VELOCITY * 2.5
			await get_tree().create_timer(0.4).timeout
			velocity.y = -JUMP_VELOCITY * 2.5
		
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "right", "forward", "Backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		body.look_at(position + direction)
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	
func flippingIt():
	flipping = true
	var index = 0
	while index <= 15:
		velocity.y = JUMP_VELOCITY - 3
		index += 1
		body.rotation.x += 24
		await get_tree().create_timer(0.03).timeout
	body.rotation.x = 0
	flipping = false
	
func _on_wall_jumper_body_entered(body):
	if body.is_in_group("wall"):
		canWallJump = true

func _on_wall_jumper_body_exited(body):
	if body.is_in_group("wall"):
		canWallJump = false
