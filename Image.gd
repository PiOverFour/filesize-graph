extends ColorRect

export(NodePath) var popup

var graph_sequence
var image_id
    
func _notification(what):
    if what == NOTIFICATION_MOUSE_ENTER:
        print("enter")
        var popup_node = get_node(popup)
        popup_node.rect_global_position = rect_global_position - Vector2(0.0, -30.0)
        popup_node.get_node("PanelContainer/LabelContainer/Size").text = 'Size: ' + str(1)
        popup_node.visible = true
        graph_sequence.highlight(image_id)
    elif what == NOTIFICATION_MOUSE_EXIT:
        print("exit")
        get_node(popup).hide()
        graph_sequence.highlight(-1)
