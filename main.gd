extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	OS.low_processor_usage_mode = true
	get_tree().connect("files_dropped", self, "drop_files")

func get_size(filepath):
#	print(filepath)
	var file = File.new()
	file.open(filepath, file.READ)
	var size = file.get_len()
	file.close()
#	print(size)
	return size
	
func get_sizes(filepaths):
#	var total_size = 0
#	var tick = OS.get_ticks_msec()

	# Update graph
	var graph = $HSplitContainer/ColorRect/PanelContainer/ScrollContainer/Graph
	graph.polyline.clear()
	var i = 0
	for filepath in filepaths:
		graph.polyline.append(Vector2(i*10, get_size(filepath) / 1000))
		graph.update()
		i += 1
	print(graph.polyline)
	
	# Add box to right UI
	var container = $HSplitContainer/VBoxContainer
#	container.

func drop_files(files, screen):
	get_sizes(files)
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
