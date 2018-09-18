extends PanelContainer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
    # Called when the node is added to the scene for the first time.
    # Initialization here
    pass

func select_image(image_id):
    var img = $ScrollContainer/GridContainer.get_child(image_id)
    var xform = img.get_viewport_transform().get_origin()
    $Popup.popup()
    $Popup.rect_position = xform

#func _process(delta):
#    # Called every frame. Delta is time since last frame.
#    # Update game logic here.
#    pass
