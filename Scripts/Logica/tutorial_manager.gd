#Extension del GameManager para el nivel del tutorial
#Implementa una maquina de estados para guiar al jugador a traves de las mecanicas

extends GameManager
class_name TutorialManager

# --- MAQUINA DE ESTADOS ---
enum TutorialState {
	WELCOME, 
	MOVE,
	TURBO,
	COLLECT_TRASH,
	AVOID_FISH,
	FINISH,
}

# --- VARIABLES ---
var current_state = TutorialState.WELCOME
var steps_timer: Timer

#Sistema de UI del tutorial
@export var tutorial_ui_scene: PackedScene 
var tutorial_ui_instance 

func _ready():
	# Configuración inicial del tutorial
	current_fuel = max_fuel
	current_eip = 0
	time_left = 9999
	
	# Inicializacion de UI
	if tutorial_ui_scene:
		tutorial_ui_instance = tutorial_ui_scene.instantiate()
		add_child(tutorial_ui_instance)
	
	#Configuracion del temporizador del flujo de eventos
	steps_timer = Timer.new()
	add_child(steps_timer)
	steps_timer.one_shot = true
	steps_timer.timeout.connect(_next_step_delayed)
	
	#Inicio de la secuencia
	show_tutorial_message("¡Bienvenido a BOAT!")
	steps_timer.wait_time = 2.0
	steps_timer.start()

func _physics_process(delta):
	#Mantiene la logica base del juego
	super._physics_process(delta)
	
	match current_state:
		TutorialState.MOVE:
			var boat = get_node(boat_node)
			#Detecta si el jugador comienza a moverse
			if boat.velocity.length() > 10:
				advance_state(TutorialState.TURBO)
				
		TutorialState.TURBO:
			var boat = get_node(boat_node)
			#Detecta si el jugador activa el turbo
			if boat.turbo_active:
				advance_state(TutorialState.COLLECT_TRASH)

#Transcripcion de los estados del tutorial
func advance_state(new_state: TutorialState):
	current_state = new_state
	
	match current_state:
		TutorialState.MOVE:
			show_tutorial_message("Mueve el bote\n(PRESIONA LA PARTE IZQUIERDA DE LA PANTALLA)")
		TutorialState.TURBO:
			show_tutorial_message("¡Muy bien!\nAhora usa el TURBO \n(presiona la parte DERECHA de la pantalla)")
		TutorialState.COLLECT_TRASH:
			show_tutorial_message("¡Recoge la basura!\nEsto recupera COMBUSTIBLE.")
			spawn_specific_trash()
		TutorialState.AVOID_FISH:
			show_tutorial_message("¡EVITA LOS PECES!\n atropellarlos disminuye\n la sustentabilidad del agua.")
			spawn_tutorial_fish()
			steps_timer.wait_time = 5.0
			steps_timer.start()
		TutorialState.FINISH:
			show_tutorial_message("META: Obtener la mayor LIMPIEZA en el agua\nantes de que acabe el tiempo.\n estas listo para jugar!")
			steps_timer.wait_time = 5.0
			steps_timer.start()

# Callback del timer para avanzar automaticamente en los pasos
func _next_step_delayed():
	if current_state == TutorialState.WELCOME:
		advance_state(TutorialState.MOVE)
	elif current_state == TutorialState.AVOID_FISH:
		advance_state(TutorialState.FINISH)
	elif current_state == TutorialState.FINISH:
		get_tree().change_scene_to_file("res://Escenas/HUD/MenuPrincipal.tscn")

func show_tutorial_message(text: String):
	if tutorial_ui_instance:
		tutorial_ui_instance.mostrar_mensaje(text)

# Calcula una posición segura para generar objetos cerca del jugador.
func _get_safe_spawn_pos(center_node: Node2D, distance: float) -> Vector2:
	var start_angle = center_node.rotation
	
	
	for i in range(8):
		var angle_check = start_angle + (i * PI / 4)
		var test_offset = Vector2.RIGHT.rotated(angle_check) * distance
		var test_pos = center_node.global_position + test_offset
		var map_coords = water_layer.local_to_map(test_pos)
		
		#Validacion de terreno
		var is_water = water_layer.get_cell_source_id(map_coords) != -1
		var is_land = collision_layer.get_cell_source_id(map_coords) != -1
		if is_water and not is_land:
			return test_pos
			
	# Fallback si no encuentra una posicion valida
	return center_node.global_position + Vector2.RIGHT.rotated(start_angle) * distance

func spawn_specific_trash():
	if trash_scenes.is_empty(): return
	var boat = get_node(boat_node)
	var trash = trash_scenes[0].instantiate()
	var safe_pos = _get_safe_spawn_pos(boat, 200.0)
	trash.global_position = safe_pos
	call_deferred("add_child", trash)
	trash.collected.connect(func(_e, _f, _t, _p): _on_tutorial_trash_collected())
	trash.collected.connect(boat.on_trash_collected)

func spawn_tutorial_fish():
	if fish_scenes.is_empty(): return
	var boat = get_node(boat_node)
	var fish = fish_scenes[0].instantiate()
	fish.costa_layer = collision_layer
	var safe_pos = _get_safe_spawn_pos(boat, 50.0)
	fish.global_position = safe_pos
	fish.hit_by_boat.connect(boat.on_fish_hit)
	call_deferred("add_child", fish)

func _on_tutorial_trash_collected():
	if current_state == TutorialState.COLLECT_TRASH:
		advance_state(TutorialState.AVOID_FISH)

func initial_setup():
	pass 

func _end_game(reason): 
	if reason == GameOverReason.FUEL:
		current_fuel = 50
		show_tutorial_message("¡Te quedaste sin gasolina!\nTen un poco más para practicar.")
	else:
		get_tree().reload_current_scene()
