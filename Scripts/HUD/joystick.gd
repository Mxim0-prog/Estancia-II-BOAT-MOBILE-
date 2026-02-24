#Implementacion de joystick virtual para dispositivos movil
# Maneja eventos de toque y arrastre para calcular un vector de dirección

extends Control

signal direction_changed(direction)

#Textura del joystic
@onready var knob = $JoystickBoton
@onready var base = $JoystickAnillo 

var touch_index = -1 #Id del dedo que controla el joystick
var joystick_radius = 60.0 #Limite visual de desplazamiento de la palanca
var deadzone_radius = 10.0 #Zona muerta para evitar movimiento involuntario

func _ready():
	#El joystick permanece oculto hasta que el jugador toca la pantalla
	visible = false

func _input(event):
	#Detecta toques en la pantalla
	if event is InputEventScreenTouch:
		
		#Si se presiona la pantalla
		if event.is_pressed():
			#Se activa el joystic del lado izquierdo de la pantalla
			if touch_index == -1 and event.position.x < get_viewport_rect().size.x / 2:
				touch_index = event.index
				
				#Posicionamiento del joystick segun la posicion del toque 
				visible = true
				global_position = event.position - (size / 2)
				knob.position = Vector2.ZERO
		
		#Fin del toque
		elif event.index == touch_index:
			#Se resetea el estado al levantar el dedo
			touch_index = -1
			visible = false 
			emit_signal("direction_changed", Vector2.ZERO)

	#Deteccion de si el dedo es arrastrado
	if event is InputEventScreenDrag and event.index == touch_index:
		var center = Vector2.ZERO
		var drag_vector = event.position - (global_position + (size / 2))
		
		#Calculo del vectir de movimiento
		if drag_vector.length() > deadzone_radius:
			# Limita la posición visual de la palanca al radio del joystick
			if drag_vector.length() > joystick_radius:
				knob.position = drag_vector.normalized() * joystick_radius
			else:
				knob.position = drag_vector
		
			emit_signal("direction_changed", drag_vector.normalized())
		else:
			# Si el dedo está dentro de la zona no activa el movimiento
			knob.position = center + drag_vector
			emit_signal("direction_changed", Vector2.ZERO)
		
