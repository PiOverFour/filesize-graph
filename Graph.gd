# Filesize graph
# Copyright © 2018 Damien Picard
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

extends Control

signal point_highlighted(curve_id, point_id)
signal points_selected(curves)  # [[id, [p, ...]], ...]

var curves = []
onready var graph_transform = Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2(0, rect_size.y))

var zoom_speed = 1.1
var zoom_start
var zoom_start_transform = Transform2D()

var select_rect = Rect2(0, 0, 0, 0)

var is_dragging = false
var is_zooming = false
var is_selecting = false

var default_font

class Point:
    var coordinates
    var display_coordinates
    var base_color
    var color
    var is_active
    var is_selected

    func _init(frame, size, color):
        self.coordinates = Vector2(frame, size)
        self.display_coordinates = coordinates
        if coordinates.y == -1:
            self.color = Color(1.0, 0.0, 0.0)
        else:
            self.color = color
        self.base_color = self.color

    func update_color():
        if self.is_active:
            self.color = Color(1.0, 1.0, 1.0)
        elif self.is_selected:
            self.color = self.base_color.lightened(0.6)
        else:
            self.color = self.base_color

class GraphCurve:
    var draw_color
    var points = []
    var graph
    const active_color = Color(1.0, 1.0, 1.0)

    func get_random_color():
        var color = Color()
        color.v = 0.8
        color.s = 0.5
        color.h = randf()
        return color

    func _init(graph):
        self.draw_color = get_random_color()
        self.graph = graph

    func add_point(frame, size, color=self.draw_color):
        self.points.append(Point.new(frame, size, color))

    func find_close_point(position):
        var min_distance = INF
        var ls
        var closest_point
        var point_local
        for p in self.points:
            point_local = graph.graph_transform * p.coordinates
            ls = (point_local - position).length_squared()
            if ls < min_distance:
                min_distance = ls
                closest_point = p
        min_distance = sqrt(min_distance)
        return [closest_point, min_distance]

    func find_points_in_rect(rect):
        rect = rect.abs()
        var selected_points = []
        for p in self.points:
            if rect.has_point(p.display_coordinates):
                selected_points.append(self.points.find(p))
        return selected_points

    func highlight(closest_point):
        for p in self.points:
            if closest_point == null or p != closest_point:
                p.is_active = false
            else:
                p.is_active = true
            p.update_color()

    func zoom_to():
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
        self.graph.zoom_to(origin, size)

    func clear():
        self.points.clear()
        self.graph.update()

    func delete():
        self.graph.curves.remove(self.graph.curves.find(self))
        self.graph.update()

func add_curve():
    var curve = GraphCurve.new(self)
    curves.append(curve)
    update_graph()
    return curve

func _ready():
    randomize()
    var label = Label.new()
    default_font = label.get_font("")
    update_graph()

func update_graph():
    for curve in curves:
        for p in curve.points:
            p.display_coordinates = graph_transform.xform(p.coordinates)
    update()

func zoom_graph(center, factor, base_transform=graph_transform):
    var transform = Transform2D()
    transform.origin -= center
    transform = transform.scaled(factor)
    transform.origin += center
    graph_transform = transform * base_transform
    update_graph()

func zoom_to(origin, size):
    if size.x == 0:  # If only one frame in sequence
        size.x = 10
        origin.x -= 5
    if size.y == 0:  # If all frames have the same size
        size.y = 2
        origin.y -= 1
    graph_transform = (Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2(0, 0))  # y-inverted transform, to account for y-down coordinate system, multiplied by...
                       * Transform2D(Vector2(rect_size.x / size.x, 0.0),  # a transform whose x vector fits the graph into window
                                     Vector2(0.0, rect_size.y / size.y),  # same for y
                                     origin * -rect_size / size   # the offset is scaled as well
                                     - Vector2(0, rect_size.y))   # and a full vertical window is subtracted
                                    )
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
            if not event.pressed:
                var modifier
                if event.shift:
                    modifier = "ADD"
                elif event.control:
                    modifier = "SUBTRACT"
                else:
                    modifier = "REPLACE"
                if select_rect.position == event.position:
                    select_point(event.position, modifier)
                else:
                    select_rect(modifier)
            else:
                select_rect.position = event.position
                select_rect.end = event.position
            update_graph()
        # Zoom
        elif event.button_index == BUTTON_WHEEL_UP:
            zoom_graph(event.position, Vector2(zoom_speed, zoom_speed))
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom_graph(event.position, Vector2(1/zoom_speed, 1/zoom_speed))

    elif event is InputEventMouseMotion:
        if is_dragging:
            # Drag
            graph_transform.origin += event.relative
            update_graph()
        elif is_zooming:
            # Zoom
            var factor = (event.position - zoom_start)
            factor.x = pow(1.01, factor.x)
            factor.y = pow(1.01, -factor.y)
            zoom_graph(rect_size / 2,
                       factor,
                       zoom_start_transform)
        elif is_selecting:
            # Select
            select_rect.end = event.position
            update_graph()
        else:
            # Highlight point
            for curve in curves:
                var ret = curve.find_close_point(event.position)
                var point = ret[0]
                var min_distance = ret[1]
                if min_distance < 10:
                    emit_signal("point_highlighted", curves.find(curve), curve.points.find(point))
                    curve.highlight(point)
                else:
                    emit_signal("point_highlighted", curves.find(curve), -1)
                    curve.highlight(null)
            update_graph()

func select_rect(mode='REPLACE'):
    var selected_points
    var selected_curves = {}
    for c_i in range(len(curves)):
        selected_curves[c_i] = []
        selected_points = curves[c_i].find_points_in_rect(select_rect)
        for p_i in range(len(curves[c_i].points)):
            if p_i in selected_points:
                if mode == 'REPLACE' or mode == 'ADD':
                    curves[c_i].points[p_i].is_selected = true
                elif mode == 'SUBTRACT':
                    curves[c_i].points[p_i].is_selected = false
            else:
                if mode == 'REPLACE':
                    curves[c_i].points[p_i].is_selected = false

            if curves[c_i].points[p_i].is_selected:
                selected_curves[c_i].append(p_i)

            curves[c_i].points[p_i].update_color()

    update_graph()
    emit_signal("points_selected", selected_curves)  # selected_curves = {c_i: [p_1, p_2, ...], ...}

func select_point(position, modifier):
    print('selecting')
    for c_i in range(len(curves)):
        var point = curves[c_i].find_close_point(position)[0]
        point = curves[c_i].points.find(point)
        for p_i in range(len(curves[c_i].points)):
            if p_i == point:
                if modifier in ['ADD', 'REPLACE']:
                    curves[c_i].points[p_i].is_selected = true
                elif modifier == 'SUBTRACT':
                    curves[c_i].points[p_i].is_selected = false
            elif modifier == 'REPLACE':
                curves[c_i].points[p_i].is_selected = false

func sizeof_fmt(num, suffix='B'):
    """From https://stackoverflow.com/a/1094933/4561348"""
    if abs(num) < 1024.0:
        return "%3d%s%s" % [num, '', suffix]
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % [num, unit, suffix]
        num /= 1024.0
    return "%3.1f%s%s" % [num, 'Yi', suffix]

func draw_axes():
    var draw_color = Color(1.0, 1.0, 1.0, 0.1)

    var lower_corner = graph_transform.affine_inverse() * Vector2(0, rect_size.y)
    var upper_corner = graph_transform.affine_inverse() * Vector2(rect_size.x, 0)
    var size = upper_corner - lower_corner

    var scale_x = log(size.x)/log(10)
    var scale_y = log(size.y)/log(2)

    var step_x = max(pow(10, floor(scale_x)), 1)
    var step_y = max(pow(2, floor(scale_y)), 4)

    var lower_x_int = lower_corner.x - fmod(lower_corner.x, step_x) - step_x
    var upper_x_int = upper_corner.x - fmod(upper_corner.x, step_x) + step_x
    var lower_y_int = lower_corner.y - fmod(lower_corner.y, step_y) - step_y
    var upper_y_int = upper_corner.y - fmod(upper_corner.y, step_y) + step_y

    for x in range(lower_x_int, upper_x_int, step_x):
        draw_line(graph_transform * Vector2(x, lower_corner.y),
                  graph_transform * Vector2(x, upper_corner.y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(x, lower_corner.y), str(x), draw_color)

    for y in range(lower_y_int, upper_y_int, step_y/4):
        draw_line(graph_transform * Vector2(lower_corner.x, y),
                  graph_transform * Vector2(upper_corner.x, y),
                  draw_color, 1.0, true)
        draw_string(default_font, graph_transform * Vector2(lower_corner.x, y), str(sizeof_fmt(y)), draw_color)

func draw_selection_rect():
    var polyline = [select_rect.position,
                select_rect.position + Vector2(select_rect.size.x, 0),
                select_rect.position + select_rect.size,
                select_rect.position + Vector2(0, select_rect.size.y),
                select_rect.position]
    draw_polyline(polyline, Color(1,1,1), 1.0, true)

func draw_curves():
    var polyline
    var colors
    for curve in curves:
        polyline = []
        colors = []
        for p in curve.points:
            polyline.append(p.display_coordinates)
            colors.append(p.color)
        if len(curve.points) > 1:
            draw_polyline_colors(polyline, colors, 1.0, true)
        for p in curve.points:
            draw_circle(p.display_coordinates, 3, p.color)

func _draw():
    draw_axes()
    draw_curves()
    if is_selecting:
        draw_selection_rect()
