extends MenuButton

var popup

func _ready():
    popup = get_popup()
    popup.add_item("Open Sequence")
    popup.add_item("Quit")
    
    popup.connect("id_pressed", self, "_on_item_pressed")

func _on_item_pressed(ID):
    if ID == 0: # Open Sequence
        get_node("/root/Main/FileDialog").popup()
    if ID == 1: # Quit
        get_tree().quit()
    print(popup.get_item_text(ID), " pressed")
