extends MenuButton

var popup

func _ready():
    popup = get_popup()
    popup.add_item("About")
    
    popup.connect("id_pressed", self, "_on_item_pressed")

func _on_item_pressed(ID):
    if ID == 0: # About
        get_node("/root/Main/AboutDialog").popup()
