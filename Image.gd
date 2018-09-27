extends ColorRect

export(NodePath) var popup
onready var image_sequence_node = get_node("../../../..")

var image_id
var curve

func show_popup():
    image_sequence_node.highlight(image_id)

func hide_popup():
    image_sequence_node.highlight(-1)

func _notification(what):
    if what == NOTIFICATION_MOUSE_ENTER:
        show_popup()
    elif what == NOTIFICATION_MOUSE_EXIT:
        hide_popup()
