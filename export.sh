#!/bin/sh

export GODOT_BIN=~/bin/Godot_v4.0.3-stable_linux.x86_64

mkdir -p export/filesize-graph.x11/
mkdir -p export/filesize-graph.win

$GODOT_BIN --export-release "Linux/X11" ./export/filesize-graph.x11/Filesize-Graph.x86_64
$GODOT_BIN --export-release "Windows Desktop" ./export/filesize-graph.win/Filesize-Graph.exe
$GODOT_BIN --export-release "macOS" ./export/filesize-graph.mac.zip

cd export

strip filesize-graph.x11/Filesize-Graph.x86_64

zip -r filesize-graph.x11.zip filesize-graph.x11/*
zip -r filesize-graph.win.zip filesize-graph.win/*
