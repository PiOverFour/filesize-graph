extends Control

export(NodePath) var sequences_container
var polyline
var display_polyline
var graph_transform = Transform2D()
var zoom_speed = 1.1
var zoom_start
var zoom_start_transform = Transform2D()

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
    graph_transform[2] = rect_size / 2
    update_graph()
    update()

func update_graph():
    for i in range(len(polyline)):
        display_polyline[i] = graph_transform.xform(polyline[i])

func zoom_graph(center, factor, base_transform=graph_transform):
    var transform = Transform2D()
    transform.origin -= center
    transform = transform.scaled(factor)
    transform.origin += center
    graph_transform = transform * base_transform
    update_graph()
    update()
    

func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_MIDDLE:
            if event.control:
                # Activate zoom
                is_zooming = event.pressed
                zoom_start = event.position
                zoom_start_transform = graph_transform
                if is_zooming:
                    mouse_default_cursor_shape = Control.CURSOR_DRAG
                else:
                    mouse_default_cursor_shape = Control.CURSOR_ARROW
            else:
                # Activate drag
                is_dragging = event.pressed
                if is_dragging:
                    mouse_default_cursor_shape = Control.CURSOR_DRAG
                else:
                    mouse_default_cursor_shape = Control.CURSOR_ARROW
                update()
        # Zoom
        elif event.button_index == BUTTON_WHEEL_UP:
            zoom_graph(event.position, Vector2(zoom_speed, zoom_speed))
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom_graph(event.position, Vector2(1/zoom_speed, 1/zoom_speed))
    # Drag
    if event is InputEventMouseMotion:
        if is_dragging:
            graph_transform[2] += event.relative
            update_graph()
            self.update()
        elif is_zooming:
            print(mouse_default_cursor_shape)
            var factor = (event.position - zoom_start)
            factor.x = pow(1.01, factor.x)
            factor.y = pow(1.01, -factor.y)
            zoom_graph(rect_size / 2,
                       factor,
                       zoom_start_transform)
            update_graph()
            self.update()

func draw_axes():
    var size = graph_transform * rect_size
    var x = size.x
    var y = size.y
    
    while x < size.x:
        draw_line(Vector2(graph_transform.origin.x, 0.0),
                  Vector2(graph_transform.origin.x, rect_size.y),
                  Color(1.0, 1.0, 1.0, 0.1), 1.0, true)
        x += 15
#    while y < size.y:
#        draw_line(Vector2(0.0, y), Vector2(rect_size.x, y), Color(1.0, 1.0, 1.0, 0.1), 1.0, true)
#        y += 15
    
func _draw():
    draw_axes()
    for point in display_polyline:
        draw_circle(point, 3, Color(1,0,0) )
    

    draw_polyline(display_polyline, Color(1.0, 1.0, 1.0, 0.5), 1.0, true)
