extends ColorRect

export(NodePath) var popup

var image_id
var curve

func show_popup():
    var popup_node = get_node(popup)
    popup_node.rect_global_position = rect_global_position - Vector2(0.0, -30.0)
    popup_node.get_node("PanelContainer/LabelContainer/Size").text = 'Size: ' + str(1)
    popup_node.visible = true

func hide_popup():
    get_node(popup).hide()

func _notification(what):
    if what == NOTIFICATION_MOUSE_ENTER:
        show_popup()
    elif what == NOTIFICATION_MOUSE_EXIT:
        hide_popup()
