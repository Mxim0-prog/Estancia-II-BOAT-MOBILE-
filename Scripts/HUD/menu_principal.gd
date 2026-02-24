#Conrol de interfaz de usuario para el menu de inicio
#Maneja la navegacion basica entre escenas (jugar nivel, tutorial o salir)
extends Control

#Inicia el nivel principal
func _on_button_pressed():
	get_tree().change_scene_to_file("res://Escenas/Nivel/PantallaCargaPresa.tscn")

#Carga el tutorial del juego
func _on_tutorial_pressed():
	get_tree().change_scene_to_file("res://Escenas/Nivel/PantallaCargaTutorial.tscn")

#Cierra el juego
func _on_salir_pressed():
	get_tree().quit()
	
