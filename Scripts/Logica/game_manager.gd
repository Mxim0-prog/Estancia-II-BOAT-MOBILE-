
#ESTE SCRIPT ACTÚA COMO EL CONTROLADOR CENTRAL DEL JUEGO. GESTIONANDO LO SIGUIENTE:
#EL ESTADO DE COMBUSTIBLE, PUNTOS, TIEMPO, 
#LAS CONDICIONES DE VICTORIA/DERROTA 
#LA INSTANCIACIÓN DINÁMICA DE ELEMENTOS EL MAPA.

extends Node
class_name GameManager

# --- SEÑALES ---
# Notifica a la UI cuando cambian los valores principales (para actualizar barras y texto).
signal stats_updated(fuel, eip, time)
# Notifica el fin del juego enviando todas las estadísticas finales para el resumen.
signal game_over(final_eip, reason, bottles, bags)

# Enum para definir claramente la causa de la derrota.
enum GameOverReason { FUEL, TIME }

# --- STATS GLOBALES DEL JUEGO ---
@export_group("Configuración de Juego")
@export var max_fuel: float = 100.0
@export var max_eip: int = 1000 	# Puntos de Impacto Ecológico (Score)
@export var initial_eip: int = 500
@export var level_time: float = 120.0 	# Tiempo en segundos

# --- ESTADO DEL JUEGO ---
var current_fuel: float
var current_eip: float
var time_left: float

# CONTADORES ESPECÍFICOS DE RECOLECCIÓN
var bottles_collected: int = 0
var bags_collected: int = 0

# --- CONSTANTES DE BALANCE ---
const EIP_DECAY_PER_SECOND = 5          # Penalización pasiva de puntaje por tiempo
const PASSIVE_FUEL_CONSUMPTION_RATE = 1 # Gasto de combustible por motor encendido
const FISH_PENALTY_EIP = 75             # Penalización de puntos al golpear peces
const FISH_PENALTY_FUEL = 2.0           # Penalización de combustible al golpear peces

# --- REFERENCIAS A NODOS Y RECURSOS ---
@export_group("Recursos y Referencias")
@export var trash_scenes: Array[PackedScene] # Variaciones de basura instanciable
@export var fish_scenes: Array[PackedScene]  # Variaciones de obstáculos/peces
@export var water_layer: TileMapLayer        # Capa de agua para determinar posiciones válidas
@export var collision_layer: TileMapLayer    # Capa de colisión (costa)
@export var boat_node: NodePath              # Referencia al jugador

# --- CANTIDAD DE ENTIDADES A SPAWNEAR ---
@export_group("Configuración de Spawning")
@export var max_trash_count: int = 75
@export var max_fish_count: int = 15

# Cache de celdas donde es válido instanciar objetos
var navigable_cells: Array[Vector2i] = []

# --- CICLO DE VIDA E INPUT ---
func _unhandled_input(event):
	# Gestiona la pausa global del juego
	if event.is_action_pressed("pausa"):
		SignalManager.emit_signal("pause_toggled")
		get_tree().get_root().set_input_as_handled()

func _ready():
	# Inicialización de valores
	current_fuel = max_fuel
	current_eip = initial_eip
	time_left = level_time
	
	# Validación de dependencias críticas
	if not water_layer or not collision_layer or boat_node.is_empty():
		print("ERROR: Falta asignar nodos en el GameManager.")
		return
	
	# Configuración diferida para asegurar que el mapa esté cargado
	call_deferred("initial_setup")

func _physics_process(delta):
	# Chequeo de condiciones de derrota
	if current_fuel <= 0:
		_end_game(GameOverReason.FUEL)
		return
	if time_left <= 0:
		_end_game(GameOverReason.TIME)
		return
	
	# Actualización de contadores temporales
	time_left -= delta
	current_eip -= EIP_DECAY_PER_SECOND * delta
	consume_fuel(PASSIVE_FUEL_CONSUMPTION_RATE * delta)
	
	# Limitacion de valores mínimos
	if current_eip < 0:
		current_eip = 0
	
	# Actualización constante a la UI
	emit_signal("stats_updated", current_fuel, current_eip, time_left)

# Finaliza el juego, pausa el árbol de escenas y muestra la pantalla de resultados
func _end_game(reason: GameOverReason):
	get_tree().paused = true
	emit_signal("game_over", current_eip, reason, bottles_collected, bags_collected)
	set_physics_process(false)

# --- MÉTODOS PÚBLICOS (API) ---

# Reduce el combustible actual. Puede ser llamado por movimiento o penalizaciones.
func consume_fuel(amount: float):
	current_fuel -= amount

# Procesa la recolección de basura, actualizando score, combustible y contadores específicos.
func collect_trash(eip_gained: int, fuel_restored: float, trash_type: String):
	# Registro estadístico por tipo
	if trash_type == "botella":
		bottles_collected += 1
	elif trash_type == "bolsa":
		bags_collected += 1
	
	# Aplicación de beneficios
	current_eip += eip_gained
	if current_eip > max_eip:
		current_eip = max_eip
	
	current_fuel += fuel_restored
	if current_fuel > max_fuel:
		current_fuel = max_fuel

# Aplica penalizaciones cuando el jugador colisiona con fauna marina.
func hit_fish():
	current_eip -= FISH_PENALTY_EIP
	current_fuel -= FISH_PENALTY_FUEL

# --- LÓGICA DE GENERACIÓN PROCEDURAL (SPAWNING) ---
# Configuración inicial del nivel: identifica área navegable y puebla el mapa.
func initial_setup():
	identify_navigable_area()
	for i in range(max_trash_count):
		spawn_trash(0, 0, "", Vector2.ZERO) # Inicialización inicial
	for i in range(max_fish_count):
		spawn_fish()

# Genera una instancia de basura en una posición navegable aleatoria.
# Se reconecta a sí misma para mantener la población de basura constante.
func spawn_trash(_eip, _fuel, _trash_type, position_to_free_up: Vector2): 
	# Libera la celda anterior para que pueda ser reutilizada
	if position_to_free_up != Vector2.ZERO:
		var freed_cell = water_layer.local_to_map(position_to_free_up)
		if not navigable_cells.has(freed_cell): 
			navigable_cells.append(freed_cell)
	
	if trash_scenes.is_empty(): return
	if navigable_cells.is_empty():
		print("GAME MANAGER: No hay más celdas libres para generar basura!")
		return 
	# Selección aleatoria de posición disponible
	var random_index = randi() % navigable_cells.size()
	var cell_to_spawn_at = navigable_cells[random_index]
	navigable_cells.remove_at(random_index)  # Reservar celda
	
	# Instanciación
	var trash_instance = trash_scenes.pick_random().instantiate()
	trash_instance.position = water_layer.map_to_local(cell_to_spawn_at)
	trash_instance.z_index = -5
	add_child(trash_instance)
	
	# Conexión de señales con el jugador y el ciclo de respawn
	var boat = get_node_or_null(boat_node)
	if boat:
		trash_instance.collected.connect(boat.on_trash_collected)
		trash_instance.collected.connect(spawn_trash.call_deferred)

# Genera una instancia de pez/obstáculo en el mapa.
func spawn_fish():
	if fish_scenes.is_empty(): return
	var fish_instance = fish_scenes.pick_random().instantiate()
	fish_instance.position = water_layer.map_to_local(navigable_cells.pick_random())
	fish_instance.costa_layer = collision_layer
	fish_instance.z_index = -5
	add_child(fish_instance)
	var boat = get_node_or_null(boat_node)
	if boat:
		fish_instance.hit_by_boat.connect(boat.on_fish_hit)
		fish_instance.hit_by_boat.connect(spawn_fish.call_deferred)
		
# Algoritmo Flood Fill para mapear todas las celdas de agua accesibles.
# Esto evita que aparezcan objetos fuera de los límites.
func identify_navigable_area():
	var boat = get_node_or_null(boat_node)
	if not boat: return
	navigable_cells.clear()
	
	# Inicio del rastreo desde la posición del jugador
	var queue: Array[Vector2i] = [water_layer.local_to_map(water_layer.to_local(boat.global_position))]
	var visited_cells: Dictionary = { queue[0]: true }
	
	while not queue.is_empty():
		var current_cell = queue.pop_front()
		navigable_cells.append(current_cell)
		
		# Revisar 4 direcciones cardinales
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_cell = current_cell + direction
			if visited_cells.has(neighbor_cell): continue
			visited_cells[neighbor_cell] = true
			
			# Verificar que sea agua y no haya colisión
			if collision_layer.get_cell_source_id(neighbor_cell) != -1 or water_layer.get_cell_source_id(neighbor_cell) == -1: continue
			queue.push_back(neighbor_cell)
