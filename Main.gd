extends Control

export(NodePath) var graph
export(NodePath) var sequences_container
const sequence_panel_scene = preload("res://ImageSequence.tscn")

var sequence_panels = []

var rexp = RegEx.new()

func _ready():
    rexp.compile("(\\d+)")
    OS.low_processor_usage_mode = true
    get_tree().connect("files_dropped", self, "drop_files")


# Filename manipulation

func get_name_and_frame(filename):
    var search = rexp.search_all(filename)
    if not len(search):
        return
    var frame_number = search[len(search)-1] # get last number
    frame_number = frame_number.strings[0]
    var padding = frame_number.length()
    var pattern = filename.replace(frame_number, '%0' + str(padding) + 'd')
    frame_number = int(frame_number)
    return [pattern, frame_number]


func get_sequence_from_file(filepath):
    var frames = []
    var pattern
    var frame_number

    var dirname = filepath.get_base_dir()
    var file_name = filepath.get_file()
    var base_pattern = get_name_and_frame(file_name)[0]

    var dir = Directory.new()
    if dir.open(dirname) == OK:
        dir.list_dir_begin(true)
        file_name = dir.get_next()
        while (file_name != ""):
            var name_frame = get_name_and_frame(file_name)
            if typeof(name_frame) != TYPE_ARRAY:
                # No pattern found. Ignore.
                file_name = dir.get_next()
                continue
            pattern = name_frame[0]
            frame_number = name_frame[1]
            if pattern == base_pattern:
                frames.append([dirname.plus_file(file_name), frame_number])
            file_name = dir.get_next()
    return frames


# FS operation

func get_size(filepath):
    var file = File.new()
    file.open(filepath, file.READ)
    var size = file.get_len()
    file.close()
    return size


# App stuff

func process_single_file(filepath):
    var filepaths = get_sequence_from_file(filepath)
    process_files(filepaths)


func process_files(filepaths):
    var sequence
    # Get sequence if only one file is passed
    if typeof(filepaths) == TYPE_STRING_ARRAY and len(filepaths) == 1:
        sequence = get_sequence_from_file(filepaths[0])
    else:
        sequence = filepaths
    sequence = Array(sequence)
    sequence.sort()

    # Update graph
    var i = 0
    var size
    var min_size = INF
    var max_size = 0
    var min_frame = INF
    var max_frame = 0
    var polyline = []
    for frame in sequence:
        size = get_size(frame[0])
        # Get extrema
        if size > max_size:
            max_size = size
        if size < min_size:
            min_size = size
        if frame[1] > max_frame:
            max_frame = frame[1]
        if frame[1] < min_frame:
            min_frame = frame[1]
        polyline.append(Vector2(i, size))
        i += 1
    var curve = get_node(graph).add_curve(polyline, sequence[0][0], Color(0.2, 0.2, 1.0))
    create_sequence_panel(curve)

func create_sequence_panel(curve):
    var sequence_panel = sequence_panel_scene.instance()
    get_node(sequences_container).add_child(sequence_panel)
    get_node(sequences_container).get_node("DragHereLabel").visible = not len(get_node(graph).curves)
    sequence_panel.graph_node = get_node(graph)
    sequence_panel.main_node = self
    sequence_panel.curve = curve
    sequence_panel.color = curve.draw_color
    for i in range(len(curve.points)):
        sequence_panel.add_image(i, str(curve.points[i].coordinates))
    sequence_panels.append(sequence_panel)

func highlight_image_in_panel(curve_id, image_id):
    sequence_panels[curve_id].highlight(image_id)

func drop_files(files, screen):
    if len(files) == 1:
        process_single_file(files[0])
    elif len(files) > 1:
        process_files(files)
