extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var polyline = [Vector2(0, 0), Vector2(100, 100), Vector2(0, 100)]
var is_dragging = false
var viewport_offset = Vector2(0, 0)

func _input(event):
	# Activate drag
#	print(event)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			is_dragging = event.pressed
	# Drag
	if is_dragging and event is InputEventMouseMotion:
		for i in range(polyline.size()):
			polyline[i] += event.relative
#			v.y += event.relative.y
		print(polyline)
		self.update()

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass
	
func _draw():
	draw_polyline(polyline, Color(1.0, 1.0, 1.0, 0.5), 1.0, true)
#	draw_line(Vector2(0,0), Vector2(100,100), Color(1.0, 1.0, 1.0), 2.0, true)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
