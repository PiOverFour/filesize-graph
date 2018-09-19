extends PanelContainer

var graph_node
var graph_sequence
var do_highlight = false
var highlight_id = 0
var color

export(NodePath) var image_container
var images = []

#func setup():
#    $BG.color = self.color

func select_image(image_id):
    var img = $ScrollContainer/GridContainer.get_child(image_id)
    var xform = img.get_viewport_transform().get_origin()
    $Popup.popup()
    $Popup.rect_position = xform

func add_image(image_id, image_path):
    var image_node = ColorRect.new()
    image_node.rect_min_size = Vector2(16, 16)
    images.append(image_node)
    get_node(image_container).add_child(image_node)

func highlight(image_id):
    do_highlight = true
    highlight_id = image_id
    self.update()

func _on_RemoveButton_pressed():
    graph_sequence.delete()

func _on_ReloadButton_pressed():
    pass # replace with function body

func _on_GoToButton_pressed():
    graph_sequence.go_to()

func line_from_rect(rect, width=1.0, position=Vector2()):
    width = Vector2(width, width)
    var line = [Vector2(position) - width / 2.0,
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 0.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 1.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(0.0, 1.0),
                Vector2(position) - width / 2.0]
    return line

func draw_highlight():
    if do_highlight:
        var position = images[highlight_id].rect_position
        var size = images[highlight_id].rect_size
        var width = 2.0
        var line = line_from_rect(size, width, position + size/2)
        draw_polyline(line, Color(0.5, 0.6, 0.5), width, true)

func draw_border():
    var width = 1.0
    var line = line_from_rect(rect_size, width)
    draw_polyline(line, self.color, width, true)

func _draw():
    draw_highlight()
    draw_border()
