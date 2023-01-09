@tool
extends Node


## Global stuff for the view system.


const __Filter := preload("res://addons/kanban_tasks/view/filter.gd")

signal filter_changed()

## The currently active filter.
var filter: __Filter = null:
	set(value):
		filter = value
		filter_changed.emit()

## The undo redo for task operations.
var undo_redo := UndoRedo.new()

## uuid of the object that should have focus. This is used to persist focus
## when updating some views.
var focus: String = ""
