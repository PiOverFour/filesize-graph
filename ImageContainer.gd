extends GridContainer

onready var main_node = get_node("../../..")


func draw_highlight():
    if main_node.do_highlight:
        var position = main_node.images[main_node.highlight_id].rect_position
        var size = main_node.images[main_node.highlight_id].rect_size
        var width = 3.0
        var line = main_node.line_from_rect(size, width, position + Vector2(width, width)/2)
        draw_polyline(line, Color(0.5, 0.6, 0.5), width, true)

func _draw():
    draw_highlight()
