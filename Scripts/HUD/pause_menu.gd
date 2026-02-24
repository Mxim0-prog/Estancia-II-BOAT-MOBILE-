#Controla la interfaz de pausa
#Gestiona la visibilidad del menu y el estado de pausa del arbol de escenas
extends CanvasLayer

#Referencias a nodos de UI
@onready var Pause_label = $CenterContainer/PanelContainer/VBoxContainer/Label
@onready var continue_button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton
@onready var restart_button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var menu_button = $CenterContainer/PanelContainer/VBoxContainer/MenuButton

func _ready():
	#Estado inicial Oculto
	hide()
	
	#Conexion de señales de botones y eventos globales
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	#Recibe la señal global para abrrir o cerrar el menu
	SignalManager.pause_toggled.connect(toggle_pause_menu)
	
# --- LOGICA DE PAUSA ---
#Alterna el estado entre la pausa del juego y la visibilidad del menu
func toggle_pause_menu():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused

# --- CALLBACKS DE BOTONES ---

func _on_continue_pressed():
	# Reanuda el juego y oculta el menú
	toggle_pause_menu()

func _on_restart_pressed():
	#Desactiva la pausa antes de recargar la escena
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	#Desactiva la pausa y cambia la escena a la del menú principal
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Escenas/HUD/MenuPrincipal.tscn")
