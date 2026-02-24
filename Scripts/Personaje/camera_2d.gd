#Script para que la camara siga suavemente al barco
#Se utiliza _process para actualizar la posicion frame a frame
extends Camera2D

@export var object_to_follow: Node2D

func _process(_delta):
	#Mantiene la camara centrada en el nodo (Barco)
	position = object_to_follow.position

func _physics_process(_delta):
	pass
