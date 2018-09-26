extends Control

export(NodePath) var graph_node
export(NodePath) var sequences_container_node
const sequence_panel_scene = preload("res://ImageSequence.tscn")

var sequences = []

var rexp = RegEx.new()

func _ready():
    rexp.compile("(\\d+)")
    OS.low_processor_usage_mode = true
    get_tree().connect("files_dropped", self, "drop_files")

class Image:
    var frame
    var size
    var filepath
    var is_existing
    var is_empty
    var is_selected = false

    func _init(frame, size, filepath, is_existing, is_empty):
        self.frame = frame
        self.size = size
        self.filepath = filepath
        self.is_existing = is_existing
        self.is_empty = is_empty

class Sequence:
    var sequence_panel
    var main_node
    var graph_node
    var curve

    var images = []
    var min_size
    var max_size
    var min_frame
    var max_frame

    func _init(main_node, graph_node, sequences_container_node):
        self.main_node = main_node
        self.graph_node = graph_node

    func create_graph_curve():
        var polyline = []
        self.curve = self.graph_node.add_curve()
        for image in self.images:
            if image.is_empty:
                self.curve.add_point(image.frame, image.size, Color(1, 0, 0))
            else:
                self.curve.add_point(image.frame, image.size)
        self.curve.zoom_to()

    func add_image(frame, size, filepath, is_existing, is_empty):
        self.images.append(Image.new(frame, size, filepath, is_existing, is_empty))

    func create_sequence_panel():
        self.sequence_panel = self.main_node.sequence_panel_scene.instance()
        main_node.get_node(main_node.sequences_container_node).add_child(sequence_panel)
        main_node.get_node(main_node.sequences_container_node).get_node("DragHereLabel").visible = not len(graph_node.curves)
        sequence_panel.graph_node = graph_node
        sequence_panel.main_node = main_node
        sequence_panel.main_sequence = self
        sequence_panel.curve = self.curve
        sequence_panel.color = self.curve.draw_color
        for i in range(len(self.images)):
            self.sequence_panel.add_image(i, str(self.curve.points[i].coordinates))

    func get_extrema():
        for image in self.images:
            var size = image.size
            var frame = image.frame
            if size > self.max_size:
                self.max_size = size
            if size < self.min_size:
                self.min_size = size
            if frame > self.max_frame:
                self.max_frame = frame
            if frame < self.min_frame:
                self.min_frame = frame

    func delete_selected():
        var dir = Directory.new()
        for image in self.images:
            if image.is_selected:
                if dir.file_exists(image.filepath):
                    print('Deleting ', image.filepath)
                    if dir.remove(image.filepath) != OK:
                        print('Could not delete ', image.filepath)

    func remove():
        self.graph_node.curves.erase(curve)
        self.curve.delete()

        main_node.get_node(main_node.sequences_container_node).get_node("DragHereLabel").visible = not len(graph_node.curves)
        main_node.get_node(main_node.sequences_container_node).remove_child(self.sequence_panel)
        main_node.sequences.erase(self)


# Filename manipulation

func get_name_and_frame(file_name):
    var search = rexp.search_all(file_name)
    if not len(search):
        return
    var frame_number = search[len(search)-1] # get last number
    frame_number = frame_number.strings[0]
    var padding = frame_number.length()
    var pattern = file_name.replace(frame_number, '%0' + str(padding) + 'd')
    frame_number = int(frame_number)
    return [pattern, frame_number]


# FS operation

func get_sequence_from_file(file_path):
    var frames = {}
    var pattern
    var min_frame = INF
    var max_frame = -INF

    var dirname = file_path.get_base_dir()
#    var file_name = filepath.get_file()
    var file_name
    var base_pattern = get_name_and_frame(file_path)[0]

    var frame_number
    var dir = Directory.new()

    # List matching files in dir
    if dir.open(dirname) == OK:
        dir.list_dir_begin(true)
        file_name = dir.get_next()
        while (file_name != ""):
            file_name = dirname.plus_file(file_name)
            var name_frame = get_name_and_frame(file_name)
            if typeof(name_frame) != TYPE_ARRAY:
                # No pattern found. Ignore.
                file_name = dir.get_next()
                continue
            pattern = name_frame[0]
            frame_number = name_frame[1]
            if pattern == base_pattern:
                frames[frame_number] = get_size(file_name)
                if frame_number < min_frame:
                    min_frame = frame_number
                if frame_number > max_frame:
                    max_frame = frame_number
            file_name = dir.get_next()

    # Add missing frames
    for i in range(min_frame, max_frame+1):
        if not i in frames:
            frames[i] = -1

    # Convert to array, to allow sorting
    var frames_array = []
    for f in frames:
        frames_array.append([f, frames[f]])
    return [base_pattern, frames_array]  # [pattern, [[frame_number, size], ...]]

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

static func image_sort(a, b):
    return a[0] < b[0]

func process_files(filepaths):
    # Get sequence if only one file is passed
    if typeof(filepaths) == TYPE_STRING_ARRAY and len(filepaths) == 1:
        filepaths = get_sequence_from_file(filepaths[0])
    var pattern = filepaths[0]
    var frames = filepaths[1]
    frames = Array(frames)  # Make sortable (?)
    frames.sort_custom(self, 'image_sort')

    # Create sequence
    var size
    var filepath
    var sequence = Sequence.new(self, get_node(graph_node), get_node(sequences_container_node))
    for frame in frames:
        size = frame[1]
        filepath = pattern % frame[0]
        sequence.add_image(frame[0], size, filepath, size != -1, size == 0)

    sequence.create_graph_curve()
    sequence.create_sequence_panel()
    sequences.append(sequence)

func drop_files(files, screen):
    if len(files) == 1:
        process_single_file(files[0])
    elif len(files) > 1:
        process_files(files)


func _on_Graph_points_selected(curves):
    for c in curves:
        print(c, ' ', curves[c])
        for i in range(len(sequences[c].images)):
            sequences[c].images[i].is_selected = i in curves[c]

func _on_Graph_point_highlighted(sequence_id, image_id):
    sequences[sequence_id].sequence_panel.highlight(image_id)
