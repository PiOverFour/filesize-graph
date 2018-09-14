extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var polyline = [Vector2(0, 0), Vector2(100, 100), Vector2(0, 100)]

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
