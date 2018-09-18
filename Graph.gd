extends Control


var sequences = []

export(NodePath) var sequences_container
const sequence_panel_scene = preload("res://ImageSequence.tscn")

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

class Sequence:
    var polyline
    var display_polyline
    var draw_color
    var graph
    var active_color = Color(1, 1, 1)
    var point_colors = []

    var sequence_panel
    var sequences_container

    func _init(polyline, color, graph, sequences_container):
        self.polyline = polyline
        self.display_polyline = polyline.duplicate()
        for i in range(len(polyline)):
            self.point_colors.append(color)
        self.draw_color = color
        self.graph = graph
        create_sequence_panel(sequences_container)
        self.sequences_container = sequences_container

    func find_close_point(position):
        var min_distance = INF
        var ls
        var current_id
        var point
        for i in range(len(polyline)):
            point = graph.graph_transform * polyline[i]
            ls = (point - position).length_squared()
            if ls < min_distance:
                min_distance = ls
                current_id = i
            point_colors[i] = draw_color
        min_distance = sqrt(min_distance)
        if min_distance < 10:
            point_colors[current_id] = active_color
            self.sequence_panel.highlight(current_id)
        graph.update()

    func create_sequence_panel(sequences_container):
        self.sequence_panel = sequence_panel_scene.instance()
        sequences_container.add_child(sequence_panel)
        sequence_panel.graph_node = self.graph
        sequence_panel.graph_sequence = self
        for i in range(len(self.polyline)):
            sequence_panel.add_image(i, str(self.polyline[i]))

    func delete():
        self.sequences_container.remove_child(self.sequence_panel)
        self.sequence_panel.queue_free()
        self.graph.sequences.remove(self.graph.sequences.find(self))
        self.graph.update()


func add_sequence(polyline, name, min_size, max_size, min_frame, max_frame, color):
    var sequence = Sequence.new(polyline, color, self, get_node(sequences_container))
    sequences.append(sequence)
    update_graph()

    update()

func _ready():
    var label = Label.new()
    default_font = label.get_font("")

    add_sequence([Vector2(0, 0), Vector2(50, 100), Vector2(60, 100)], "truc", 0, 100, 0, 60, Color(1.0, 0.2, 0.2))
    graph_transform[2] = rect_size / 2
    update_graph()
    update()

func update_graph():
    for sequence in sequences:
        for i in range(len(sequence.polyline)):
            sequence.display_polyline[i] = graph_transform.xform(sequence.polyline[i])

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
            var factor = (event.position - zoom_start)
            factor.x = pow(1.01, factor.x)
            factor.y = pow(1.01, -factor.y)
            zoom_graph(rect_size / 2,
                       factor,
                       zoom_start_transform)
        else:
            for sequence in sequences:
                sequence.find_close_point(event.position)

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
    var lower_x_int = lower_corner.x - fmod(lower_corner.x, step_x) - step_x
    var upper_x_int = upper_corner.x - fmod(upper_corner.x, step_x) + step_x*2
    var lower_y_int = lower_corner.y - fmod(lower_corner.y, step_y) - step_y
    var upper_y_int = upper_corner.y - fmod(upper_corner.y, step_y) + step_y*2

    var draw_color = Color(1.0, 1.0, 1.0, 0.1)

    for x in range(lower_x_int, upper_x_int, step_x/2):
        draw_line(graph_transform * Vector2(x, lower_corner.y),
                  graph_transform * Vector2(x, upper_corner.y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(x, upper_corner.y), str(x), draw_color)

    for y in range(lower_y_int, upper_y_int, step_y/2):
        draw_line(graph_transform * Vector2(lower_corner.x, y),
                  graph_transform * Vector2(upper_corner.x, y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(lower_corner.x, y), str(y), draw_color)

func _draw():
    draw_axes()
    for sequence in sequences:
        draw_polyline(sequence.display_polyline, sequence.draw_color, 1.0, true)
        for i in range(len(sequence.display_polyline)):
            draw_circle(sequence.display_polyline[i], 3, sequence.point_colors[i] )
