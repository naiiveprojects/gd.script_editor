@tool
extends EditorPlugin

const PATH_CONFIG := "res://addons/nv.script_editor/config.cfg"
const PATH_STAY_IN_SCRIPT := "text_editor/behavior/navigation/stay_in_script_editor_on_node_selected"
const PATH_SCRIPT_TOGGLE := {
	"TextEditor": [0, 1, 0],
	"ScriptTextEditor": [0, 0, 1, 0],
	"EditorHelp": [2, 0],
}

var _switching := false
var config: Dictionary = {
	"docked": true,
	"tab_visible": false,
	"stay_in_scirpt": false, # Stay in script Editor when clicking on node in tree
}

var script_editor: ScriptEditor = EditorInterface.get_script_editor()
var script_menu: HBoxContainer = script_editor.get_child(0).get_child(0)
var script_container: HSplitContainer = script_editor.get_child(0).get_child(1)
var script_list: VSplitContainer = script_container.get_child(0)
var script_tab: TabContainer = script_container.get_child(1).get_child(0)
var script_list_item: ItemList = script_list.get_child(0).get_child(1)
var script_tabbar: TabBar = script_tab.get_tab_bar()

var dock := MarginContainer.new()
var dock_tab: TabContainer = null
var menu_container := HBoxContainer.new()
var menu_tab := Button.new()


func _enter_tree() -> void:
	
	var units := [
			script_editor, script_menu, script_container, script_list,
			script_tab, script_list_item
	]
	for u in units: if u == null:
		printt("ERROR"," NV Script Editor", "Missing Refrences")
		return
	
	EditorInterface.get_editor_settings().set(PATH_STAY_IN_SCRIPT, config.stay_in_scirpt)
	script_tab.set_tab_alignment(TabBar.ALIGNMENT_LEFT)
	script_list_item.item_selected.connect(_editor_script_changed)
	
	menu_tab.toggle_mode = true
	menu_tab.flat = true
	menu_tab.text = "Tabs"
	menu_tab.tooltip_text = "Show Script Editor TabBar"
	menu_tab.toggled.connect(_update_tabs)
	
	menu_container.add_child(menu_tab)
	script_menu.add_child(menu_container)
	script_menu.move_child(menu_container, 3)
	
	dock.name = "Script"
	config_load()


func _exit_tree():
	config_save()
	
	if dock.is_inside_tree():
		dock.remove_child(script_list)
		script_container.add_child(script_list)
		script_container.move_child(script_list, OK)
		remove_control_from_docks(dock)
	
	menu_container.queue_free()
	dock.queue_free()


func _editor_script_changed(idx: int = 0) -> void:
	if dock.is_inside_tree():
		dock_tab.current_tab = dock.get_index()
		EditorInterface.set_main_screen_editor("Script")
	
	if script_tab.are_tabs_visible():
		script_list_item.select(idx)
	
	script_tabbar.set_tab_title(idx, script_list_item.get_item_text(idx))
	script_tabbar.set_tab_icon(idx, script_list_item.get_item_icon(idx))
	_connect_script_list_toggle(script_tab.get_current_tab_control())


func _connect_script_list_toggle(node: Control) -> void:
	var button: Control = node
	if PATH_SCRIPT_TOGGLE.has(button.get_class()):
		for path in PATH_SCRIPT_TOGGLE.get(button.get_class()):
			button = button.get_child(path)
		if button and button is Button:
			if not button.pressed.is_connected(_switch_script_list_dock):
				button.pressed.connect(_switch_script_list_dock)


func _update_tabs(active: bool = false) -> void:
	script_tab.set_tabs_visible(active)
	
	if not active: return
	if not script_tab.tab_changed.is_connected(_editor_script_changed):
		script_tab.tab_changed.connect(_editor_script_changed)
	
	for idx in script_tabbar.get_tab_count():
		script_tabbar.set_tab_title(idx, script_list_item.get_item_text(idx))
		script_tabbar.set_tab_icon(idx, script_list_item.get_item_icon(idx))


func _switch_script_list_dock() -> void:
	if _switching: return
	_switching = true
	
	if dock.is_inside_tree():
		dock_tab = dock.get_parent()
		dock.remove_child(script_list)
		script_container.add_child(script_list)
		script_container.move_child(script_list, OK)
		remove_control_from_docks(dock)
	else:
		script_container.remove_child(script_list)
		dock.add_child(script_list)
		
		if dock_tab == null:
			add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, dock)
			dock_tab = dock.get_parent()
		else:
			dock_tab.add_child(dock)
		dock_tab.set_current_tab(dock.get_index())
	
	await get_tree().process_frame
	
	script_list.show()
	_switching = false


func config_save() -> void:
	config.docked = dock.is_inside_tree()
	config.tab_visible = menu_tab.is_pressed()
	
	var cfg := ConfigFile.new()
	for item in config.keys():
		cfg.set_value("NVSE", item, config.get(item))
	
	cfg.save(PATH_CONFIG)


func config_load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH_CONFIG) != OK:
		_switch_script_list_dock()
		return
	
	for item in config.keys():
		config[item] = cfg.get_value("NVSE", item, config.get(item))
	
	if !script_list.visible or config.docked:
		_switch_script_list_dock()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░ Title: NV Script Editor
# ░░█▀█░█▀█░█░░░█░░░█░█░█▀▀░░ Act: Extend Script Editor Feature
# ░░█░█░█▀█░░▀▄░░▀▄░▀▄▀░█▀▀░░ Cast[Editor, ScriptEditor]
# ░░▀░▀░▀░▀░░░▀░░░▀░░▀░░▀▀▀░░ Writters[@illlustr,]
# ░ Projects ░░░░░░░░░░░░░░░░ https://github.com/naiiveprojects
