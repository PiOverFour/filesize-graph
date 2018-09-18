extends Control

export(NodePath) var sequences_container
var polyline
var display_polyline
var graph_location
var graph_scale = Vector2(1, -1)
var zoom_speed = 1.1
var zoom_start

var is_dragging = false
var is_zooming = false

var min_size
var max_size
var min_frame
var max_frame

func add_sequence(polyline, name, min_size, max_size, min_frame, max_frame):
    self.polyline = polyline
    display_polyline = polyline.duplicate()

    update()

func _ready():
    add_sequence([Vector2(0, 0), Vector2(50, 100), Vector2(60, 100)], "truc", 0, 100, 0, 60)
    graph_location = rect_size / 2
    update_graph()
    update()

func update_graph():
#    var transform = Transform2D().scaled(graph_scale)
#    for i in range(len(polyline)):
#        display_polyline[i] = transform * polyline[i] + graph_location
    var transform = Transform2D().scaled(graph_scale).translated(Vector2(graph_location.x, 0.0)).translated(Vector2(0.0, -graph_location.y))
    print(transform)
    for i in range(len(polyline)):
        display_polyline[i] = transform.xform(polyline[i])

func zoom_graph(center, factor):
    print(center)
    graph_scale *= factor
#    graph_location. += 
    update_graph()
    update()
    

func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_MIDDLE:
            if event.control:
                # Activate zoom
                is_zooming = event.pressed
                zoom_start = event.position
            else:
                # Activate drag
                is_dragging = event.pressed
        # Zoom
        elif event.button_index == BUTTON_WHEEL_UP:
            zoom_graph(event.position, Vector2(zoom_speed, zoom_speed))
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom_graph(event.position, Vector2(1/zoom_speed, 1/zoom_speed))
    # Drag
    if event is InputEventMouseMotion:
        if is_dragging:
            graph_location += event.relative
            update_graph()
            self.update()
        elif is_zooming:
            zoom_graph(event.position - zoom_start)
            update_graph()
            self.update()

func draw_axes():
    pass
    
func _draw():
#    draw_set_transform(graph_location, 0.0, graph_scale)
    for point in display_polyline:
        draw_circle(point, 3, Color(1,0,0) )
    
    draw_axes()

    draw_polyline(display_polyline, Color(1.0, 1.0, 1.0, 0.5), 1.0, true)
