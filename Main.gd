# Filesize graph
# Copyright © 2018 Damien Picard
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

extends Control

export(NodePath) var graph_node
export(NodePath) var sequences_container_node
const sequence_panel_scene = preload("res://ImageSequence.tscn")

var sequences = []

func _ready():
    OS.low_processor_usage_mode = true
    get_tree().connect("files_dropped", self, "drop_files")
    parse_cmdline_args()

func parse_cmdline_args():
    var cmdline_args = OS.get_cmdline_args()
    if "-h" in cmdline_args or "--help" in cmdline_args:
        print("""Usage: filesize-graph [--file=FILE]
Visualise file sequences in a graph, in order to see
missing frames and local variations.

  -h, --help                 display this help and exit
      --file=FILE            open the sequence of which this file is part
""")
        get_tree().quit()
    for arg in cmdline_args:
        if arg.begins_with("--file="):
            process_files(arg.right(len("--file=")))


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
    var sequences_container_node
    var curve

    var images = []
    var min_size
    var max_size
    var min_frame
    var max_frame

    var rexp = RegEx.new()

    func _init(main_node, filepaths):
        rexp.compile("(\\d+)")
        self.main_node = main_node
        self.graph_node = main_node.get_node(main_node.graph_node)
        self.sequences_container_node = main_node.get_node(main_node.sequences_container_node)

        self.process_files(filepaths)
        self.create_graph_curve()
        self.create_sequence_panel()

    func add_image(frame, size, filepath, is_existing, is_empty):
        self.images.append(Image.new(frame, size, filepath, is_existing, is_empty))

    func clear_images():
        self.images.clear()
        self.clear_sequence_panel()
        self.clear_graph_curve()

    func reload():
        var filepath = self.images[0].filepath
        self.clear_images()
        self.process_files(filepath)
        self.fill_graph_curve()
        self.fill_sequence_panel()

    # Graph curve

    func create_graph_curve():
        self.curve = self.graph_node.add_curve()
        self.fill_graph_curve()
        self.curve.zoom_to()

    func fill_graph_curve():
        var polyline = []
        for image in self.images:
            if image.is_empty:
                self.curve.add_point(image.frame, image.size, Color(1, 0, 0))
            else:
                self.curve.add_point(image.frame, image.size)
        self.graph_node.update_graph()

    func clear_graph_curve():
        self.curve.clear()


    # Sequence panel

    func create_sequence_panel():
        self.sequence_panel = self.main_node.sequence_panel_scene.instance()
        self.main_node.get_node(main_node.sequences_container_node).add_child(sequence_panel)
        self.main_node.get_node(main_node.sequences_container_node).get_node("DragHereLabel").visible = not len(graph_node.curves)
        self.sequence_panel.graph_node = graph_node
        self.sequence_panel.main_node = main_node
        self.sequence_panel.main_sequence = self
        self.sequence_panel.curve = self.curve
        self.sequence_panel.color = self.curve.draw_color
        self.fill_sequence_panel()

    func fill_sequence_panel():
        for i in range(len(self.images)):
            self.sequence_panel.add_image(i, str(self.curve.points[i].coordinates))

    func clear_sequence_panel():
        self.sequence_panel.clear()


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
        self.reload()
        # Disconnect signal from confirm dialog popup
        main_node.get_node("ConfirmDeleteDialog").disconnect("confirmed", self, "delete_selected")


    func remove():
        self.curve.delete()
        self.graph_node.curves.erase(curve)

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

    static func get_size(filepath):
        var file = File.new()
        file.open(filepath, file.READ)
        var size = file.get_len()
        file.close()
        return size

    func get_sequence_from_file(file_path):

        file_path = file_path.replace('\\', '/')
        var frames = {}
        var pattern
        var min_frame = INF
        var max_frame = -INF

        var dirname = file_path.get_base_dir()
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
                # Compare pattern to base pattern, eliminate non-matching files
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


    # App stuff

    static func image_sort(a, b):
        return a[0] < b[0]

    func process_files(filepaths):
        # Get sequence if only one file is passed
        if typeof(filepaths) == TYPE_STRING_ARRAY:
            filepaths = get_sequence_from_file(filepaths[0])
        elif typeof(filepaths) == TYPE_STRING:
            filepaths = get_sequence_from_file(filepaths)
        var pattern = filepaths[0]
        var frames = filepaths[1]
        frames = Array(frames)  # Make sortable (?)
        frames.sort_custom(self, 'image_sort')

        # Create sequence
        var size
        var filepath
        for frame in frames:
            size = frame[1]
            filepath = pattern % frame[0]
            self.add_image(frame[0], size, filepath, size != -1, size == 0)


func process_files(filepaths):
    var sequence = Sequence.new(self, filepaths)
    sequences.append(sequence)

func drop_files(files, screen):
    process_files(files)

func _on_Graph_points_selected(curves):
    for c in curves:
        for i in range(len(sequences[c].images)):
            sequences[c].images[i].is_selected = i in curves[c]

func _on_Graph_point_highlighted(sequence_id, image_id):
    sequences[sequence_id].sequence_panel.highlight(image_id)
