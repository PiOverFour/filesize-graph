extends PopupPanel


func _ready() -> void:
    $AboutLabel.text = $AboutLabel.text.format(
        {"version": ProjectSettings.get_setting("application/config/version"),
        "godot_version": Engine.get_version_info()["string"]}
    )
