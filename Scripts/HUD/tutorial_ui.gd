#Gestiona las ventanas emergentes de instrucciones del tutorial         

extends CanvasLayer

@onready var panel_container = $Control/HBoxContainer/PanelContainer
@onready var label_instruccion = $Control/HBoxContainer/PanelContainer/LabelInstruccion

func _ready():
	# Configuracion inicial del pivote para que las escalas se animen desde el centro
	panel_container.pivot_offset = panel_container.size / 2
	panel_container.scale = Vector2.ZERO
	visible = true

func mostrar_mensaje(texto: String):
	#Actualizacion del contenido
	label_instruccion.text = texto
	
	# Espera un frame para que el contenedor recalcule su tamaño con el nuevo texto
	await get_tree().process_frame
	
	# Recalcula el centro tras el nuevo tamaño
	panel_container.pivot_offset = panel_container.size / 2
	
	#Animacion
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)	
	panel_container.scale = Vector2.ZERO
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.6)

func ocultar_mensaje():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.3)
