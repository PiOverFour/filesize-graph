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

extends MenuButton

var popup

func _ready():
    popup = get_popup()
    popup.add_item(tr("Open sequence"), 0, KEY_MASK_CTRL | KEY_O)
    popup.add_item(tr("Quit"), 1, KEY_MASK_CTRL | KEY_Q)

    popup.id_pressed.connect(_on_item_pressed)

func _on_item_pressed(ID):
    if ID == 0: # Open Sequence
        get_node("/root/Main/FileDialog").popup()
    if ID == 1: # Quit
        get_tree().quit()
