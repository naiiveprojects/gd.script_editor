tool
extends EditorPlugin

const PATH_CONFIG := "res://addons/nv.script_editor/config.cfg"
const PATH_STAY_IN_SCRIPT := "text_editor/navigation/stay_in_script_editor_on_node_selected"

var _switching: bool = false

var config: Dictionary = {
	"docked": true,
	"tab_visible": false,
	"split_mode": false, # share space with script editor
	"stay_in_scirpt": false, # Stay in script editor when clicking on node in tree
}

# Refrences
var editor: EditorInterface = get_editor_interface()
var script_editor: ScriptEditor = editor.get_script_editor()
var script_menu: HBoxContainer = script_editor.get_child(0).get_child(0)
var script_container: HSplitContainer = script_editor.get_child(0).get_child(1)
var script_list: VSplitContainer = script_container.get_child(0)  # List of script & methode
var script_tab: TabContainer = script_container.get_child(1) # TextEditor

var dock := MarginContainer.new()
var dock_tab: TabContainer = null

var menu_container := HBoxContainer.new()
var menu_split := ToolButton.new()
var menu_tab := ToolButton.new()


func _enter_tree() -> void:
	var units := [dock, editor, script_editor, script_menu, script_container, script_list, script_tab]
	for u in units: if u == null:
		printt("ERROR"," NV Script Editor", "Missing Refrences")
		return
	
	editor.get_editor_settings().set(PATH_STAY_IN_SCRIPT, config.stay_in_scirpt)
	script_tab.set_tab_align(TabContainer.ALIGN_LEFT)
	script_tab.set_drag_to_rearrange_enabled(true)
	
	menu_split.toggle_mode = true
	menu_split.text = "Split"
	menu_split.hint_tooltip = "Split Mode.\nshare space with Script Editor "
	menu_split.hint_tooltip += "when selecting item in script panel outside script editor"
	menu_split.connect("pressed", self, "_editor_script_changed")
	
	menu_tab.toggle_mode = true
	menu_tab.text = "Tabs"
	menu_tab.hint_tooltip = "Show Script Editor Tabs"
	menu_tab.connect("toggled", script_tab, "set_tabs_visible")
	
	menu_container.add_child(menu_split)
	menu_container.add_child(menu_tab)
	script_menu.add_child(menu_container)
	script_menu.move_child(menu_container, 3)
	
	dock.name = 'Script'
	script_editor.connect("editor_script_changed", self, "_editor_script_changed")
	
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


func _editor_script_changed(script: Script = null) -> void:
	if menu_split.pressed:
		script_editor.show()
	elif script:
		script_editor.show()
		editor.edit_resource(script)
	else:
		editor.set_main_screen_editor("Script")
	
	if dock.is_inside_tree():
		dock_tab.current_tab = dock.get_index()
	
	_connect_toggle_scripts_panel()


func _connect_toggle_scripts_panel() -> void:
	var tab: Control = script_tab.get_current_tab_control().get_child(0)
	if not tab is VSplitContainer: return
	tab.get_parent().name = script_editor.get_current_script().resource_path.get_basename().get_file()
	var toggle: ToolButton = tab.get_child(0).get_child(2).get_child(0)
	if not toggle.is_connected("pressed", self, "_switch_script_list_dock"):
		toggle.connect("pressed", self, "_switch_script_list_dock")


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
		dock_tab.current_tab = dock.get_index()
	
	yield(get_tree(), "idle_frame")
	
	script_list.show()
	_switching = false


func config_save() -> void:
	config.docked = dock.is_inside_tree()
	config.split_mode = menu_split.pressed
	config.tab_visible = menu_tab.pressed
	
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
	
	menu_split.pressed = config.split_mode
	menu_tab.pressed = config.tab_visible
	
	if !script_list.visible or config.docked:
		_switch_script_list_dock()



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░ Title: NV Script Editor
# ░░█▀█░█▀█░█░░░█░░░█░█░█▀▀░░ Act: Extend Script Editor Feature
# ░░█░█░█▀█░░▀▄░░▀▄░▀▄▀░█▀▀░░ Cast[Editor, ScriptEditor]
# ░░▀░▀░▀░▀░░░▀░░░▀░░▀░░▀▀▀░░ Writters[@illlustr,]
# ░ Projects ░░░░░░░░░░░░░░░░ https://github.com/naiiveprojects
