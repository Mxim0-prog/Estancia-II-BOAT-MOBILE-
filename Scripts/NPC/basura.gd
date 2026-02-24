#Define un objeto recolectable en el juego
#Contiene la informacion sobre la recompenza que recibe el jugador 
#Gestiona su propia deteccion

extends Area2D

#señal emitida al ser recolectada, pasando las propiedades al receptor
signal collected(eip, fuel, trash_type, position_to_free_up)

# --- PROPIEDADES DEL OBJETO ---
#Ajustables en el editor para crear distintos valores
@export var eip_to_give: int = 20 #Puntos otorgados
@export var fuel_to_give: float = 2 #Combustible restaurado
@export var trash_type: String = "unknown" #Tipo de basura
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	#Configuracion de deteccion de colisiones 
	body_entered.connect(_on_body_entered)
	animated_sprite.play("idle")

func _on_body_entered(body):
#Validacion: solo el juador puede recolectar este objeto
	if body.is_in_group("player"):
		#Notifica la recoleccion con todos los datos necesarios.
		emit_signal("collected", eip_to_give, fuel_to_give, trash_type, global_position)
		#Se elimina a si mismo 
		queue_free()
