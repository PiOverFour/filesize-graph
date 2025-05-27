# Filesize Graph
# Copyright © 2018-2025 Damien Picard
# Copyright © 2018-2025 Les Fées Spéciales
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

extends ColorRect

@export var popup: NodePath
@onready var image_sequence_node = get_node("../../../../..")

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
