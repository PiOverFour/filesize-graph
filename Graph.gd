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

var default_font

func add_sequence(polyline, name, min_size, max_size, min_frame, max_frame):
    self.polyline = polyline
    display_polyline = polyline.duplicate()

    update()

func _ready():
    var label = Label.new()
    default_font = label.get_font("")
    
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

func log10(x):
    return log(x)/log(10)
    
func draw_axes():
    var lower_corner = graph_transform.affine_inverse() * Vector2(0, 0)
    var upper_corner = graph_transform.affine_inverse() * rect_size
    var size = upper_corner - lower_corner
    var scale_x = log10(size.x)
    var scale_y = log10(size.y)
    var step_x = pow(10, floor(scale_x))
    var step_y = pow(10, floor(scale_y))
#    print(size)
    print(lower_corner, ' ', upper_corner)
    print(step_x)
    var lower_x_int = lower_corner.x - fmod(lower_corner.x, step_x) - step_x
    var upper_x_int = upper_corner.x - fmod(upper_corner.x, step_x) + step_x*2
    var lower_y_int = lower_corner.y - fmod(lower_corner.y, step_y) - step_y
    var upper_y_int = upper_corner.y - fmod(upper_corner.y, step_y) + step_y*2
    print(lower_x_int)
    
    var draw_color = Color(1.0, 1.0, 1.0, 0.1)
    
    for x in range(lower_x_int, upper_x_int, step_x/10):
        draw_line(graph_transform * Vector2(x, lower_corner.y),
                  graph_transform * Vector2(x, upper_corner.y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(x, upper_corner.y), str(x), draw_color)
#        g( Font font, Vector2 position, String text, Color modulate=Color( 1, 1, 1, 1 ), int clip_w=-1 )

    for y in range(lower_y_int, upper_y_int, step_y/10):
        draw_line(graph_transform * Vector2(lower_corner.x, y),
                  graph_transform * Vector2(upper_corner.x, y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(lower_corner.x, y), str(y), draw_color)

#    while y < size.y:
#        draw_line(Vector2(0.0, y), Vector2(rect_size.x, y), Color(1.0, 1.0, 1.0, 0.1), 1.0, true)
#        y += 15
    
func _draw():
    draw_axes()
    for point in display_polyline:
        draw_circle(point, 3, Color(1,0,0) )
    

    draw_polyline(display_polyline, Color(1.0, 1.0, 1.0, 0.5), 1.0, true)
