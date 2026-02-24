#Controlador del personaje principal
#Maneja el movimiento basado en fisica, input, consumo de combustible y colisiones

extends CharacterBody2D

# Referencia al gestor global para reportar consumo y eventos
@export var game_manager: Node

# --- PARAMETROS DE FISICA ---
const SPEED = 175.0
const TURBO_MULTIPLIER = 1.8
const ROTATION_SPEED = 10.0
const ADJUSTMENT_ANGLE = PI / 2 #Ajuste para la orientacion del sprite


# --- PARAMETROS DE CONSUMO ---
const FUEL_CONSUMPTION_RATE = 2
const FUEL_TURBO_EXTRA_CONSUMPTION = 4

# --- INPUT Y MOVIL ---
@export var joystick_node_path: NodePath
@export var turbo_button_node_path: NodePath
var _joystick
var _turbo_button
var target_angle = 0.0
var mobile_direction = Vector2.ZERO
var turbo_active = false
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Inicializacion de controles tactiles
	_joystick = get_node_or_null(joystick_node_path)
	_turbo_button = get_node_or_null(turbo_button_node_path)
	if _joystick:
		_joystick.direction_changed.connect(_on_joystick_direction_changed)
	if _turbo_button:
		_turbo_button.pressed.connect(_on_turbo_button_pressed)
		_turbo_button.released.connect(_on_turbo_button_released)

func _physics_process(delta):
	if game_manager == null:
		print("ERROR: El barco no tiene asignado un GameManager.")
		return
	
	#Obtencion de direccion
	var direction = get_input_direction()
	var is_moving = direction.length() > 0
	var is_turbo_on = turbo_active or Input.is_action_pressed("Turbo")
	
	if is_moving:
		#Calculo de velocidad
		var current_speed = SPEED
		if is_turbo_on:
			current_speed *= TURBO_MULTIPLIER
		
		velocity = direction.normalized() * current_speed
		animated_sprite.play("move_boat")
		
		#Calculo y reporte del consumo de combustible al GameManager
		var fuel_to_consume = FUEL_CONSUMPTION_RATE * delta
		if is_turbo_on:
			fuel_to_consume += FUEL_TURBO_EXTRA_CONSUMPTION * delta
		game_manager.consume_fuel(fuel_to_consume)
		
		#Calculo de rotacion suave hacia la direccion del movimiento
		target_angle = direction.angle() + ADJUSTMENT_ANGLE
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("static_boat")
	
	#Aplicacion de rotacion y movimiento fisico
	rotation = lerp_angle(rotation, target_angle, delta * ROTATION_SPEED)
	move_and_slide()

# --- MANEJO DE EVENTOS ---

#Callback ejecutado cuando se recolecta basura
func on_trash_collected(eip_gained, fuel_restored, trash_type, _position_to_free_up):
	if game_manager:
		game_manager.collect_trash(eip_gained, fuel_restored, trash_type)

#Callback ejecutado al arrollar a un pez
func on_fish_hit():
	if game_manager:
		game_manager.hit_fish()

# --- INPUT HANDLING ---

#Unifica la entrada del teclado y el joystick virtual
func get_input_direction():
	var keyboard_direction = Vector2.ZERO
	if Input.is_action_pressed("move_right"): keyboard_direction.x += 1
	if Input.is_action_pressed("move_left"): keyboard_direction.x -= 1
	if Input.is_action_pressed("move_down"): keyboard_direction.y += 1
	if Input.is_action_pressed("move_up"): keyboard_direction.y -= 1
	if keyboard_direction.length() > 0: return keyboard_direction
	else: return mobile_direction

#Señales de funciones tactiles 
func _on_joystick_direction_changed(direction): mobile_direction = direction
func _on_turbo_button_pressed(): turbo_active = true
func _on_turbo_button_released(): turbo_active = false
