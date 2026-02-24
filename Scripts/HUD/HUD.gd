#Gestiona la capa de interfaz de usuario
#Se encarga de mostrar las estadisticas en tiempo real y la pantalla de game over
extends CanvasLayer

# --- REFERENCIAS A UI ---
@export var game_manager_node: NodePath

#Indicadores de estado en el juego
@export var fuel_bar: TextureProgressBar
@export var fuel_label: Label
@export var eip_bar: TextureProgressBar
@export var eip_label: Label
@export var time_label: Label

#Nodos de la pantalla de Game Over
@export var game_over_panel: Panel
@export var title_label: Label      
@export var score_label: Label
@export var reason_label: Label 
@export var restart_button: Button
@export var menu_button: Button

#Estadisticas 
@export var bottle_count_label: Label
@export var bag_count_label: Label
@export var co2_reduction_label: Label

var game_manager

#Estimaciones en gramos para el calculo del impacto ambiental
const CO2_PER_BOTTLE_GRAMS = 50  
const CO2_PER_BAG_GRAMS = 13     

func _ready():
	game_manager = get_node_or_null(game_manager_node)
	if not game_manager:
		print("ERROR en HUD: No se asignó el GameManager.")
		return
	
	#Conexion a las señales del GameManager para actualizaciones 
	game_manager.stats_updated.connect(_on_stats_updated)
	game_manager.game_over.connect(_on_game_over)
	
	#Configuraciones de botones
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	
	#Estado inicial del panel
	if game_over_panel:
		game_over_panel.visible = false
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

#Actualiza las barras de progreso y el temporizador frame a frame
func _on_stats_updated(fuel, eip, time):
	if fuel_bar:
		fuel_bar.value = (fuel / game_manager.max_fuel) * 100
		var fuel_display_value = round((fuel / game_manager.max_fuel) * 100)
		fuel_label.text = "%d%%" % fuel_display_value

	if eip_bar:
		eip_bar.value = (eip / float(game_manager.max_eip)) * 100
		var eip_display_value = round((eip / float(game_manager.max_eip)) * 100)
		eip_label.text = "%d%%" % eip_display_value

	if time_label:
		var minutes = int(time) / 60
		var seconds = int(time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

#Despliega la pantalla de resultados cuando termina el juego
func _on_game_over(final_eip, reason, bottles, bags):
	if game_over_panel:
		
		#Configuracion de textos
		if title_label:
			title_label.text = "Fin del Juego!!"
		
		#Causa de fin de juego
		if reason_label:
			match reason:
				game_manager.GameOverReason.FUEL:
					reason_label.text = "Se acabo el combustible :("
				game_manager.GameOverReason.TIME:
					reason_label.text = "El tiempo se acabo!!"
		
		#Puntos conseguidos
		if score_label:
			var score_percentage = round((float(final_eip) / game_manager.max_eip) * 100)
			score_label.text = "Limpieza conseguida: %d%%" % score_percentage
		
		# Reporte de objetos conseguidos
		if bottle_count_label:
			bottle_count_label.text = "Botellas Recogidas: %d" % bottles
		if bag_count_label:
			bag_count_label.text = "Bolsas Recogidas: %d" % bags
		
		#Calculo de CO2 reducido
		if co2_reduction_label:
			var total_co2_grams = (bottles * CO2_PER_BOTTLE_GRAMS) + (bags * CO2_PER_BAG_GRAMS)
			if total_co2_grams >= 1000:
				var total_co2_kg = total_co2_grams / 1000.0
				co2_reduction_label.text = "CO2 Reducido: %.2f kg" % total_co2_kg
			else:
				co2_reduction_label.text = "CO2 Reducido: %d g" % total_co2_grams
		
		#Mostrar el panel y capturar el input
		game_over_panel.visible = true
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		
#Funcion del boton "Reiniciar"
func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

#Funcion del boton "Menu"
func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Escenas/HUD/MenuPrincipal.tscn")

#Funcion del boton "Pausa"
func _on_pause_button_pressed():
	SignalManager.emit_signal("pause_toggled")
