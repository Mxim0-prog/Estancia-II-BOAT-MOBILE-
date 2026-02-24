#Controla el comportamiento de los enemigos (peces)
#Impementa un movimiento aleatorio con deteccion de colisiones para evitar que "Salgan del agua"
extends Area2D

#Señal emitida cuando el jugador colisiona con el pez
signal hit_by_boat

#Velocidad de movimiento
@export var move_speed: float = 40.0

#Referencia al tilemap de costa para deteccion de colisiones
var costa_layer: TileMapLayer

var _direction = Vector2.ZERO
var _move_timer: Timer

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Sistema de cambio de direccion aleatorio mediante un Timer
	_move_timer = Timer.new()
	_move_timer.wait_time = randf_range(2.0, 5.0) # Cambia de dirección cada 2 a 5 segundos
	_move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(_move_timer)
	_move_timer.start()
	
	_pick_new_direction()
	$AnimatedSprite2D.play("default")

func _physics_process(delta):
	#Validacion de dependencia
	if not collision_layer:
		return

	# --- ALGORITMO DE DETECCION DE COSTA ---
	#Predice la siguiente posicion antes de moverse
	var next_position = global_position + _direction * move_speed * delta
	
	#Convierte la posicion global en coordenadas del mapa de tiles
	var map_coords = costa_layer.local_to_map(next_position)
	
	#Verifica si en esa coordenada hay una celda de colisión
	var has_collision = costa_layer.get_cell_source_id(map_coords) != -1

	if has_collision:
		#Si hay una colision cambia la direccion inmediatamente
		_pick_new_direction()
	else:
		#Si no hay colision se mueve a esa celda
		global_position = next_position


func _pick_new_direction():
	# Genera un vector de direccion aleatorio
	_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	
	#Orienta el sprite hacia la direccion de movimiento 
	if has_node("AnimatedSprite2D"):
		self.rotation = _direction.angle() + (PI / 2)

func _on_move_timer_timeout():
	# Cuando el timer se complete cambia la direccion
	_pick_new_direction()

func _on_body_entered(body):
	#Deteccion de impacto con el jugador
	if body.is_in_group("player"):
		emit_signal("hit_by_boat")
		queue_free() #Elimina el pez tras el impacto
