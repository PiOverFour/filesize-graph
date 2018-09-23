extends ColorRect

export(NodePath) var popup

var curve
var image_id

func _notification(what):
    if what == NOTIFICATION_MOUSE_ENTER:
        var popup_node = get_node(popup)
        popup_node.rect_global_position = rect_global_position - Vector2(0.0, -30.0)
        popup_node.get_node("PanelContainer/LabelContainer/Size").text = 'Size: ' + str(1)
        popup_node.visible = true
#        curve.highlight(image_id)
    elif what == NOTIFICATION_MOUSE_EXIT:
        get_node(popup).hide()
        curve.highlight(null)
