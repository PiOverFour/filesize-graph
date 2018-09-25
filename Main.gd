extends Control

export(NodePath) var graph_node
export(NodePath) var sequences_container_node
const sequence_panel_scene = preload("res://ImageSequence.tscn")

var sequences = []

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
    
    func _init(main_node, graph_node, sequences_container_node):
        self.main_node = main_node
        self.graph_node = graph_node
    
    func create_graph_curve():
        var polyline = []
        for image in self.images:
            polyline.append(Vector2(image.frame, image.size))
        self.curve = self.graph_node.add_curve(polyline)
        
    func create_sequence_panel():
        self.sequence_panel = self.main_node.sequence_panel_scene.instance()
        main_node.get_node(main_node.sequences_container_node).add_child(sequence_panel)
        main_node.get_node(main_node.sequences_container_node).get_node("DragHereLabel").visible = not len(graph_node.curves)
        sequence_panel.graph_node = graph_node
        sequence_panel.main_node = main_node
        sequence_panel.curve = self.curve
        sequence_panel.color = self.curve.draw_color
        for i in range(len(self.images)):
            self.sequence_panel.add_image(i, str(self.curve.points[i].coordinates))
    
    func add_image(frame, size, filepath, is_existing, is_empty):
        self.images.append(Image.new(frame, size, filepath, is_existing, is_empty))
        
    
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
                frames.append([frame_number, dirname.plus_file(file_name)])
            file_name = dir.get_next()
    return frames  # [frame_number, filepath]


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

static func image_sort(a, b):
    return a[1] < b[1]

func process_files(filepaths):
    # Get sequence if only one file is passed
    if typeof(filepaths) == TYPE_STRING_ARRAY and len(filepaths) == 1:
        filepaths = get_sequence_from_file(filepaths[0])
    filepaths = Array(filepaths)
    filepaths.sort_custom(self, 'image_sort')

    # Update graph
    var i = 0
    var size
    
    var sequence = Sequence.new(self, get_node(graph_node), get_node(sequences_container_node))
    for frame in filepaths:
        size = get_size(frame[1])
        
        sequence.add_image(frame[0], size, frame[1], size == -1, size == 0)
#        # Get extrema
#        if size > max_size:
#            max_size = size
#        if size < min_size:
#            min_size = size
#        if frame[1] > max_frame:
#            max_frame = frame[1]
#        if frame[1] < min_frame:
#            min_frame = frame[1]
    sequence.create_graph_curve()
    sequence.create_sequence_panel()
    sequences.append(sequence)

func highlight_image_in_panel(sequence_id, image_id):
    sequences[sequence_id].sequence_panel.highlight(image_id)

func drop_files(files, screen):
    if len(files) == 1:
        process_single_file(files[0])
    elif len(files) > 1:
        process_files(files)
