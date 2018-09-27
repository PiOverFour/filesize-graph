extends PanelContainer

var main_node
var graph_node
var main_sequence
var curve
var do_highlight = false
var highlight_id = 0
var color

export(NodePath) var image_container
var images = []
const image_scene = preload("res://Image.tscn")


func select_image(image_id):
    var img = $ScrollContainer/GridContainer.get_child(image_id)
    var xform = img.get_viewport_transform().get_origin()
    $Popup.popup()
    $Popup.rect_position = xform

func add_image(image_id, image_path):
    var image_node = image_scene.instance()
    image_node.rect_min_size = Vector2(16, 16)
    image_node.curve = curve
    image_node.image_id = image_id
    images.append(image_node)
    get_node(image_container).add_child(image_node)

func clear():
    for image_node in get_node(image_container).get_children():
        get_node(image_container).remove_child(image_node)
    images.clear()

func highlight(image_id):
    do_highlight = image_id != -1
    highlight_id = image_id
    get_node("VBoxContainer/ScrollContainer/ImageContainer").update()

func _on_RemoveButton_pressed():
    main_sequence.remove()
    self.queue_free()

func _on_DeleteSelectedButton_pressed():
    # Create signal on popup
    main_node.get_node("ConfirmDeleteDialog").connect("confirmed", main_sequence, "delete_selected")
    main_node.get_node("ConfirmDeleteDialog").popup()

func _on_ReloadButton_pressed():
    main_sequence.reload()

func _on_ZoomToButton_pressed():
    curve.zoom_to()

func line_from_rect(rect, width=1.0, position=Vector2()):
    width = Vector2(width, width)
    var line = [Vector2(position) - width / 2.0,
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 0.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 1.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(0.0, 1.0),
                Vector2(position) - width / 2.0]
    return line

func draw_border():
    var width = 1.0
    var line = line_from_rect(rect_size, width)
    draw_polyline(line, self.color, width, true)

func _draw():
    draw_border()