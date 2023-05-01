@tool
extends AcceptDialog


const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __StepData := preload("res://addons/kanban_tasks/data/step.gd")
const __StepEntry := preload("res://addons/kanban_tasks/view/details/step_entry.gd")

var board_data: __BoardData
var data_uuid: String

var __step_data: __StepData

@onready var category_select: OptionButton = %Category
@onready var description_edit: TextEdit = %Description
@onready var step_holder: VBoxContainer = %StepHolder
@onready var steps_panel_container: PanelContainer = %PanelContainer
@onready var create_step_edit: LineEdit = %CreateStepEdit
@onready var step_details: VBoxContainer = %StepDetails
@onready var close_step_details_button: Button = %CloseStepDetails
@onready var step_edit: TextEdit = %StepEdit


func _ready() -> void:
	about_to_popup.connect(__on_about_to_popup)
	create_step_edit.text_submitted.connect(__create_step)
	close_step_details_button.pressed.connect(__close_step_details)
	notification(NOTIFICATION_THEME_CHANGED)


func _notification(what: int) -> void:
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(steps_panel_container):
				steps_panel_container.add_theme_stylebox_override(&"panel", get_theme_stylebox(&"panel", &"Tree"))
			if is_instance_valid(create_step_edit):
				create_step_edit.right_icon = get_theme_icon(&"Add", &"EditorIcons")
			if is_instance_valid(close_step_details_button):
				close_step_details_button.icon = get_theme_icon(&"Close", &"EditorIcons")


func update() -> void:
	if description_edit.text_changed.is_connected(__on_description_changed):
		description_edit.text_changed.disconnect(__on_description_changed)
	description_edit.text = board_data.get_task(data_uuid).description
	description_edit.text_changed.connect(__on_description_changed)

	title = "Task Details: " + board_data.get_task(data_uuid).title

	if category_select.item_selected.is_connected(__on_category_selected):
		category_select.item_selected.disconnect(__on_category_selected)
	category_select.clear()
	for uuid in board_data.get_categories():
		var i = Image.create(16, 16, false, Image.FORMAT_RGB8)
		i.fill(board_data.get_category(uuid).color)
		var t = ImageTexture.create_from_image(i)
		category_select.add_icon_item(t, board_data.get_category(uuid).title)
		category_select.set_item_metadata(-1, uuid)
		if uuid == board_data.get_task(data_uuid).category:
			category_select.select(category_select.item_count - 1)

	category_select.item_selected.connect(__on_category_selected)

	for step in step_holder.get_children():
		step.queue_free()
	for step in board_data.get_task(data_uuid).steps:
		var entry = __StepEntry.new()
		entry.step_data = step
		step_holder.add_child(entry)

	step_details.visible  = is_instance_valid(__step_data)
	if is_instance_valid(__step_data):
		if step_edit.text_changed.is_connected(__on_step_details_changed):
			step_edit.text_changed.disconnect(__on_step_details_changed)
		step_edit.text = __step_data.details
		step_edit.text_changed.connect(__on_step_details_changed)


# Workaround for godotengine/godot#70451
func popup_centered_ratio_no_fullscreen(ratio: float = 0.8) -> void:
	var viewport: Viewport = get_parent().get_viewport()
	popup(Rect2i(Vector2(viewport.position) + viewport.size / 2.0 - viewport.size * ratio / 2.0, viewport.size * ratio))


func edit_step_details(step: __StepData) -> void:
	if is_instance_valid(__step_data):
		__step_data.changed.disconnect(update)
	__step_data = step
	__step_data.changed.connect(update)
	update()
	step_edit.set_caret_line(step_edit.get_line_count())
	step_edit.set_caret_column(len(step_edit.get_line(step_edit.get_line_count() - 1)))
	step_edit.grab_focus.call_deferred()


func close_step_details(step: __StepData) -> void:
	if __step_data == step:
		__close_step_details()


func __close_step_details() -> void:
	__step_data.changed.disconnect(update)
	__step_data = null
	update()


func __on_step_details_changed():
	if __step_data.changed.is_connected(update):
		__step_data.changed.disconnect(update)
	__step_data.details = step_edit.text
	__step_data.changed.connect(update)


func __on_about_to_popup() -> void:
	if is_instance_valid(__step_data):
		__close_step_details()
	update()
	if board_data.get_task(data_uuid).description.is_empty():
		description_edit.grab_focus.call_deferred()


func __on_description_changed() -> void:
	board_data.get_task(data_uuid).description = description_edit.text


func __on_category_selected(index: int) -> void:
	board_data.get_task(data_uuid).category = category_select.get_item_metadata(index)


func __create_step(text: String) -> void:
	if text.is_empty():
		return
	var steps = board_data.get_task(data_uuid).steps
	var data = __StepData.new(text)
	steps.append(data)
	board_data.get_task(data_uuid).steps = steps
	create_step_edit.text = ""
	update()
	if is_instance_valid(__step_data):
		for step in step_holder.get_children():
			if step.step_data == data:
				step.grab_focus.call_deferred()
