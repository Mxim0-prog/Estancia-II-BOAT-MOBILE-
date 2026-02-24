#Gestiona la escena de transicion hacia el nivel principal
#Muestra datos educativos mientras simula la carga de recursos
extends Control

#Datos ambientales
var datos_ambientales = [
	'Una botella de plástico tarda aproximadamente 450 años en descomponerse',
	"Más de 8 millones de toneladas de plástico terminan en los océanos cada año, amenazando la vida marina.",
	"Reciclar una botella de plástico ahorra suficiente energía para encender una bombilla de 60W durante 6 horas.",
	"Se estima que en 2050 habrá más plástico que peces en el océano.",
	"Las tortugas marinas a menudo confunden las bolsas de plástico flotantes con medusas (su comida favorita), lo que les causa bloqueos digestivos fatales.",
	"Pequeños gestos, como usar bolsas reutilizables y evitar plásticos de un solo uso, marcan una gran diferencia.",
	"La contaminación del agua no solo daña a los animales, también puede afectar la salud humana.",
	"Solo el 9% de todo el plástico producido en la historia se ha reciclado.",
	"Una sola colilla de cigarro puede contaminar hasta 50 litros de agua potable debido a las toxinas que libera.",
	"De toda el agua en la Tierra, solo el 2.5% es agua dulce, y de esa cantidad, menos del 1% es fácilmente accesible para el consumo humano.",
	"El vidrio es uno de los pocos materiales que se puede reciclar infinitamente sin perder calidad ni pureza.",
	"Una lata de aluminio reciclada puede volver a estar en el estante de una tienda como una lata nueva en tan solo 60 días.",
	"Un solo litro de aceite de cocina usado tirado por el desagüe puede contaminar 1,000 litros de agua. ¡Nunca lo tires al fregadero!",
	"Un popote de plástico se usa en promedio durante 20 minutos, pero tarda hasta 500 años en desaparecer del ambiente.",
]

# --- NODOS UI ---
@onready var dato_ambiental_label: Label = $VBoxContainer/DatoAmbientalLabel
@onready var barra_progreso: ProgressBar = $VBoxContainer/BarraProgreso
@onready var texto_cargando_label: Label = $VBoxContainer/BarraProgreso/CenterContainer/TextoCargandoLabel

var escena_nivel_juego = "res://Escenas/Nivel/presa_la_boca.tscn"
var carga_terminada = false

func _ready():
	#Configuracion de la barra de progreso
	barra_progreso.min_value = 0
	barra_progreso.max_value = 100
	barra_progreso.value = 0
	
	#Selecciona un dato aleatorio
	var indice_aleatorio = randi() % datos_ambientales.size()
	dato_ambiental_label.text = datos_ambientales[indice_aleatorio]
	iniciar_carga_simulada()
	#Conexion para input del usuario
	barra_progreso.gui_input.connect(_on_barra_progreso_gui_input)

#Simula la carga de recursos
func iniciar_carga_simulada():
	var duracion_carga_segundos = 5.0
	var tween = get_tree().create_tween()
	tween.tween_property(barra_progreso, "value", 100.0, duracion_carga_segundos)
	tween.tween_callback(terminar_carga)

func terminar_carga():
	texto_cargando_label.text = "¡comenzar!"
	carga_terminada = true

#Gestiona el input para iniciar el nivel una vez cargado
func _on_barra_progreso_gui_input(event: InputEvent):
	#Ignorar cualquier input si la carga no  ha terminado
	if not carga_terminada:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file(escena_nivel_juego)
			
	elif event is InputEventScreenTouch:
		if event.is_pressed():
			get_tree().change_scene_to_file(escena_nivel_juego)
