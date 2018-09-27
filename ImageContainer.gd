extends Container

export(int) var image_size = 20
export(int) var margin_min = 2
onready var main_node = get_node("../../..")

var row_offset = 0
var previous_height = -1

func _ready():
    _on_ImageContainer_sort_children()

func draw_highlight():
    if main_node.do_highlight:
        var position = main_node.images[main_node.highlight_id].rect_position
        var size = main_node.images[main_node.highlight_id].rect_size
        var width = 3.0
        var line = main_node.line_from_rect(size, width, position + Vector2(width, width)/2)
        draw_polyline(line, Color(0.5, 0.6, 0.5), width, true)

func _draw():
    draw_highlight()


func _on_ImageContainer_sort_children():
    # Calculate margin
    var scrollbar = $"../VScrollBar"

    var width = rect_size.x
    var square_size = image_size + margin_min
    var row_squares = floor(width / square_size)
    var margin = (width - (row_squares*image_size)) / (row_squares-1)
    square_size = image_size + margin
    # Layout images
    for i in range(get_child_count()):
        fit_child_in_rect(get_child(i), Rect2(square_size * fmod(i, row_squares),
                                              square_size * (floor(i / row_squares)-row_offset),
                                              image_size, image_size))
    # Update Scrollbar
    if get_child_count() and previous_height != rect_size.y:
        var column_squares = ceil(get_child_count() / row_squares)
        var page = ceil(rect_size.y / square_size)
        scrollbar.max_value = floor(column_squares) + 1
        scrollbar.page = min(page, scrollbar.max_value)

func _on_VScrollBar_value_changed(value):
    row_offset = value
    _on_ImageContainer_sort_children()
