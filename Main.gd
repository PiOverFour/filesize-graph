extends Control


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
            print(base_pattern, " ", pattern)
            if pattern == base_pattern:
                frames.append([dirname.plus_file(file_name), frame_number])
            file_name = dir.get_next()
    print(frames)
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
    print("processing")
    var sequence
    # Get sequence if only one file is passed
    if typeof(filepaths) == TYPE_STRING_ARRAY and len(filepaths) == 1:
        sequence = get_sequence_from_file(filepaths[0])
    else:
        sequence = filepaths
    sequence = Array(sequence)
    sequence.sort()

    # Update graph
    var graph = $HSplitContainer/ColorRect/PanelContainer/Graph
    graph.polyline.clear()
    var i = 0
    var size
    var min_size = INF
    var max_size = 0
    var min_frame = INF
    var max_frame = 0
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
        graph.polyline.append(Vector2(i, size))
        i += 1
    graph.max_size = max_size
    graph.min_size = min_size
    graph.max_frame = max_frame
    graph.min_frame = min_frame
    for i in range(graph.polyline.size()):
        graph.polyline[i].y = graph.polyline[i].y * graph.rect_size.y / max_size
        graph.polyline[i].x = graph.polyline[i].x * graph.rect_size.x / max_frame
#    print(graph.polyline)
    graph.update()

    # Add box to right UI
    var container = $HSplitContainer/VBoxContainer
#	container.


func drop_files(files, screen):
    if len(files) == 1:
        process_single_file(files[0])
    elif len(files) > 1:
        process_files(files)
