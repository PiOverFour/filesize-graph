# Filesize graph
# Copyright © 2018-2023 Damien Picard
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

extends Container

@export var image_size: int = 20
@export var margin_min: int = 2
@onready var main_node = get_node("../../../..")

var row_offset = 0
var previous_height = -1


func _ready():
    _on_ImageContainer_sort_children()


func draw_highlight():
    if main_node.do_highlight:
        var position = main_node.images[main_node.highlight_id].position
        var size = main_node.images[main_node.highlight_id].size
        var width = 3.0
        var line = main_node.line_from_size(size, width, position + Vector2(width, width)/2)
        draw_polyline(line, Color(0.5, 0.6, 0.5), width, true)


func _draw():
    draw_highlight()


func _on_ImageContainer_sort_children():
    # Calculate margin
    var scrollbar = $"../VScrollBar"

    var width = size.x
    var square_size = image_size + margin_min
    var row_squares = floor(width / square_size)
    var margin = (width - (row_squares*image_size)) / (row_squares-1)
    square_size = image_size + margin

    # Layout images
    for i in range(get_child_count()):
        fit_child_in_rect(get_child(i), Rect2(square_size * fmod(i, row_squares),
                                              square_size * (floor(i / row_squares)-row_offset),
                                              image_size, image_size))

    # Update scrollbar
    if get_child_count() and previous_height != size.y:
        var column_squares = ceil(get_child_count() / row_squares)
        var page = ceil(size.y / square_size)
        scrollbar.max_value = floor(column_squares) + 1
        scrollbar.page = min(page, scrollbar.max_value)


func _on_VScrollBar_value_changed(value):
    row_offset = value
    _on_ImageContainer_sort_children()
