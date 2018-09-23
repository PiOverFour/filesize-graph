extends Control

var sequences = []

export(NodePath) var sequences_container
const sequence_panel_scene = preload("res://ImageSequence.tscn")

var graph_transform = Transform2D()

var zoom_speed = 1.1
var zoom_start
var zoom_start_transform = Transform2D()

var select_rect = Rect2(0, 0, 0, 0)

var is_dragging = false
var is_zooming = false
var is_selecting = false

var default_font

class Image:
    var coordinates
    var display_coordinates
    var is_empty
    var is_missing
    var color
    var is_active
    var is_selected
    var filepath
    
    func _init(coordinates, color, filepath):
        self.coordinates = coordinates
        self.display_coordinates = coordinates
        self.color = color
        self.filepath = filepath

class Sequence:
#    var polyline
#    var display_polyline
    var draw_color
    var points = []
    var graph
    const active_color = Color(1.0, 1.0, 1.0)
#    var point_colors = []

    var sequence_panel
    var sequences_container

    func get_random_color():
        var color = Color()
        color.v = 1.0
        color.s = rand_range(0.4, 0.6)
        color.h = randf()
        return color

    func _init(points, color, graph, sequences_container):
        color = get_random_color()
        print(color.h, ' ', color.s, ' ', color.v)
        for p in points:
            self.points.append(Image.new(p, color, ''))
#            self.polyline = polyline
#            self.display_polyline = polyline.duplicate()
#        for i in range(len(polyline)):
#            self.point_colors.append(color)
        self.draw_color = color
        self.graph = graph
        self.create_sequence_panel(sequences_container)
        self.sequences_container = sequences_container
        self.go_to()

    func find_close_point(position):
        var min_distance = INF
        var ls
        var closest_point
        var point_local
#        for i in range(len(polyline)):
        for p in self.points:
            point_local = graph.graph_transform * p.coordinates
            ls = (point_local - position).length_squared()
            if ls < min_distance:
                min_distance = ls
                closest_point = p
        min_distance = sqrt(min_distance)
        if min_distance < 10:
            self.sequence_panel.highlight(closest_point)
            self.highlight(closest_point)
        else:
            self.sequence_panel.highlight(null)
            self.highlight(null)
        self.graph.update()

    func highlight(closest_point):
        for p in self.points:
            if closest_point == null or p != closest_point:
                p.color = self.draw_color
            else:
                p.color = self.active_color

    func go_to():
        var min_x = INF
        var max_x = -INF
        var min_y = INF
        var max_y = -INF
        for point in self.points:
            if point.coordinates.x < min_x:
                min_x = point.coordinates.x
            if point.coordinates.x > max_x:
                max_x = point.coordinates.x
            if point.coordinates.y < min_y:
                min_y = point.coordinates.y
            if point.coordinates.y > max_y:
                max_y = point.coordinates.y
        var origin = Vector2(min_x, min_y)
        var size = Vector2(max_x - min_x, max_y - min_y)
        self.graph.go_to(origin, size)

    func create_sequence_panel(sequences_container):
        self.sequence_panel = sequence_panel_scene.instance()
        sequences_container.add_child(self.sequence_panel)
        self.sequence_panel.graph_node = self.graph
        self.sequence_panel.graph_sequence = self
        self.sequence_panel.color = self.draw_color
        for i in range(len(self.points)):
            self.sequence_panel.add_image(i, str(self.points[i].coordinates))

    func delete():
        self.sequences_container.remove_child(self.sequence_panel)
        self.sequence_panel.queue_free()
        self.graph.sequences.remove(self.graph.sequences.find(self))
        self.sequences_container.get_node("DragHereLabel").visible = len(graph.sequences) < 1
        self.graph.update()

func add_sequence(points, name, color):
    var sequence = Sequence.new(points, color, self, get_node(sequences_container))
    sequences.append(sequence)
    get_node(sequences_container).get_node("DragHereLabel").visible = not len(sequences)
    update_graph()

func _ready():
    randomize()
    var label = Label.new()
    default_font = label.get_font("")

    update_graph()

func update_graph():
    for sequence in sequences:
#        for i in range(len(sequence.polyline)):
#            sequence.display_polyline[i] = graph_transform.xform(sequence.polyline[i])
        for p in sequence.points:
            p.display_coordinates = graph_transform.xform(p.coordinates)
    update()

func zoom_graph(center, factor, base_transform=graph_transform):
    var transform = Transform2D()
    transform.origin -= center
    transform = transform.scaled(factor)
    transform.origin += center
    graph_transform = transform * base_transform
#    print(graph_transform)
    update_graph()

func go_to(origin, size):
    graph_transform = Transform2D(Vector2(rect_size.x / size.x, 0.0), Vector2(0.0, rect_size.y / size.y), origin * -rect_size / size)
#    print(origin)
#    print(size)
#    print(graph_transform)
    update_graph()

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
                update()
            if is_dragging or is_zooming:
                mouse_default_cursor_shape = Control.CURSOR_DRAG
            else:
                mouse_default_cursor_shape = Control.CURSOR_ARROW
        elif event.button_index == BUTTON_LEFT:
            # Select
            is_selecting = event.pressed
            select_rect.position = event.position
            select_rect.end = event.position
            update()
        # Zoom
        elif event.button_index == BUTTON_WHEEL_UP:
            zoom_graph(event.position, Vector2(zoom_speed, zoom_speed))
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom_graph(event.position, Vector2(1/zoom_speed, 1/zoom_speed))

    elif event is InputEventMouseMotion:
        if is_dragging:
            graph_transform.origin += event.relative
            update_graph()
        elif is_zooming:
            var factor = (event.position - zoom_start)
            factor.x = pow(1.01, factor.x)
            factor.y = pow(1.01, -factor.y)
            zoom_graph(rect_size / 2,
                       factor,
                       zoom_start_transform)
        elif is_selecting:
            select_rect.end = event.position
            update_graph()
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
    var upper_x_int = upper_corner.x - fmod(upper_corner.x, step_x) + step_x
    var lower_y_int = lower_corner.y - fmod(lower_corner.y, step_y) - step_y
    var upper_y_int = upper_corner.y - fmod(upper_corner.y, step_y) + step_y

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

func draw_selection_rect():
    var polyline = [select_rect.position,
                select_rect.position + Vector2(select_rect.size.x, 0),
                select_rect.position + select_rect.size,
                select_rect.position + Vector2(0, select_rect.size.y),
                select_rect.position]
    draw_polyline(polyline, Color(1,1,1), 1.0, true)


func _draw():
    # Prevent drawing outside canvas
    var canvas_rid = get_canvas_item()
    VisualServer.canvas_item_set_clip(canvas_rid, true)
    VisualServer.canvas_item_set_custom_rect(canvas_rid, true, Rect2(Vector2(), rect_size))
    
    draw_axes()
    var polyline
    var colors
    for sequence in sequences:
        polyline = []
        colors = []
        for p in sequence.points:
            polyline.append(p.display_coordinates)
            colors.append(p.color)
        draw_polyline_colors(polyline, colors, 1.0, true)
        for p in sequence.points:
            draw_circle(p.display_coordinates, 3, p.color)
    if is_selecting:
        draw_selection_rect()