extends Control

export(NodePath) var line_node
export(NodePath) var sequences_container
var polyline = [Vector2(0, 0), Vector2(100, 100), Vector2(0, 100)]
#var transform_matrix = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0))
var graph_location
var graph_scale = Vector2(1, -1)

var is_dragging = false
var viewport_offset = Vector2(0, 0)
var min_size
var max_size = 100
var min_frame
var max_frame = 100

func add_sequence(polyline, min_size, max_size, min_frame, max_frame):
    polyline = polyline
    graph_scale = Vector2(
                          float(rect_size.x) / (max_frame),
                          float(rect_size.y) / (max_size ))
    update()

func _ready():
     graph_location = Vector2(0, rect_size.y)

func _gui_input(event):
    # Activate drag
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            is_dragging = event.pressed
    # Drag
    if is_dragging and event is InputEventMouseMotion:
        graph_location += event.relative
        self.update()

    
func _draw():
    draw_set_transform(graph_location, 0.0, graph_scale)
    draw_polyline(polyline, Color(1.0, 1.0, 1.0, 0.5), 1.0, true)
