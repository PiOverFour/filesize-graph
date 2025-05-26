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

extends PanelContainer

var main_node
var graph_node
var main_sequence
var curve
var do_highlight = false
var highlight_id = 0
var color

var images = []
const image_scene = preload("res://Image.tscn")

@export var image_container: NodePath
@onready var scroll_bar_node = get_node("MarginContainer/VBoxContainer/ScrollContainer/VScrollBar")


func add_image(image_id):
    var image_node = image_scene.instantiate()
    image_node.custom_minimum_size = Vector2(16, 16)
    image_node.curve = curve
    image_node.image_id = image_id
    if main_sequence.images[image_id].size == -1:
        image_node.color = Color(1, 0, 0)
    images.append(image_node)
    get_node(image_container).add_child(image_node)


func clear():
    for image_node in get_node(image_container).get_children():
        get_node(image_container).remove_child(image_node)
    images.clear()


func highlight(image_id):
    do_highlight = image_id != -1
    highlight_id = image_id
    if do_highlight:
        show_popup(image_id)
    else:
        hide_popup()

    get_node("MarginContainer/VBoxContainer/ScrollContainer/ImageContainer").queue_redraw()


func sizeof_fmt(num, suffix='B'):
    """From https://stackoverflow.com/a/1094933/4561348"""
    if abs(num) < 1024.0:
        return "%3d%s%s" % [num, '', suffix]
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % [num, unit, suffix]
        num /= 1024.0
    return "%3.1f%s%s" % [num, 'Yi', suffix]


func show_popup(image_id):
    var image_node = images[image_id]
    var image_size
    if main_sequence.images[image_id].size != -1:
        image_size = sizeof_fmt(main_sequence.images[image_id].size)
    else:
        image_size = "frame missing"
    var popup_node = main_node.get_node("Tooltip")
    popup_node.position.x = min(image_node.global_position.x+15,
        self.global_position.x + self.size.x - popup_node.size.x - 40
    )
    popup_node.position.y = min(image_node.global_position.y+15,
        self.size.y - 80
    )
    popup_node.get_node("MarginContainer/LabelContainer/LabelContainerValues/Frame").text = str(main_sequence.images[image_node.image_id].frame)
    popup_node.get_node("MarginContainer/LabelContainer/LabelContainerValues/Size").text = image_size
    popup_node.get_node("MarginContainer/LabelContainer/LabelContainerValues/FileName").text = str(main_sequence.images[image_node.image_id].filepath.get_file())
    popup_node.visible = true


func hide_popup():
    var popup_node = main_node.get_node("Tooltip")
    popup_node.hide()


func _gui_input(event):
    if event.is_pressed():
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            scroll_bar_node.value -= 2.0
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            scroll_bar_node.value += 2.0


func _on_RemoveButton_pressed():
    main_sequence.remove()
    self.queue_free()


func _on_DeleteSelectedButton_pressed():
    # Create signal on popup
    main_node.get_node("ConfirmDeleteDialog").confirmed.connect(main_sequence.delete_selected)
    main_node.get_node("ConfirmDeleteDialog").popup()


func _on_ShowInExplorerButton_pressed():
    OS.shell_open("file://" + main_sequence.seqpath.get_base_dir())


func _on_ReloadButton_pressed():
    main_sequence.reload()


func _on_ZoomToButton_pressed():
    curve.zoom_to()


func line_from_size(rect, width=1.0, position=Vector2()):
    width = Vector2(width, width)
    var line = [Vector2(position) - width / 2.0,
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 0.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(1.0, 1.0),
                Vector2(position) - width / 2.0 + Vector2(rect) * Vector2(0.0, 1.0),
                Vector2(position) - width / 2.0]
    return line


func draw_border():
    var width = 1.0
    var line = line_from_size(self.size, width)
    draw_polyline(line, self.color, width, true)


func _draw():
    draw_border()
