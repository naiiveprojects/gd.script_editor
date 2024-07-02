tool
extends EditorPlugin

enum ID_MAIN_EDITOR { TWO, THREE, SCRIPT, ASSETLIB }

const MAIN_EDITOR := [ "2D", "3D", "Script", "AssetLib" ]
const PATH_CONFIG := "res://addons/nv.script_editor/config.cfg"
const PATH_STAY_IN_SCRIPT := "text_editor/navigation/stay_in_script_editor_on_node_selected"

var _switching: bool = false
var config: Dictionary = {
	"docked": true,
	"split_main": "3D", # Switch to this editor when split enable
	"stay_in_scirpt": false, # Stay in script editor when clicking on node in tree
}

var editor: EditorInterface = get_editor_interface()
var script_editor: ScriptEditor = editor.get_script_editor()
var script_menu: HBoxContainer = script_editor.get_child(0).get_child(0)
var script_container: HSplitContainer = script_editor.get_child(0).get_child(1)
var script_list: VSplitContainer = script_container.get_child(0) 
var script_tab: TabContainer = script_container.get_child(1)
var script_list_item: ItemList = script_list.get_child(0).get_child(1)

var dock := MarginContainer.new()
var dock_tab: TabContainer = null
var menu_container := HBoxContainer.new()
var menu_split := ToolButton.new()
var menu_split_group := ButtonGroup.new()
var menu_split_editor := [Button.new(), Button.new()]
var menu_tab := ToolButton.new()


func _enter_tree() -> void:
	var units := [
			dock, editor, script_editor, script_menu,
			script_container, script_list, script_tab,
			script_list_item,
	]
	for u in units: if u == null:
		printt("ERROR"," NV Script Editor", "Missing Refrences")
		return
	
	dock.set_name(MAIN_EDITOR[ID_MAIN_EDITOR.SCRIPT])
	
	script_tab.set_tab_align(TabContainer.ALIGN_LEFT)
	script_tab.set_drag_to_rearrange_enabled(true)
	
	script_editor.connect("editor_script_changed", self, "_connect_scripts_panel_toggle")
	script_list_item.connect("item_selected", self, "_editor_script_selected")
	
	_create_menu()


func _exit_tree():
	config_save()
	
	if dock.is_inside_tree():
		dock.remove_child(script_list)
		script_container.add_child(script_list)
		script_container.move_child(script_list, OK)
		remove_control_from_docks(dock)
	
	menu_container.queue_free()
	dock.queue_free()


func _menu_tab_toggled(active: bool = false) -> void:
	script_tab.set_tabs_visible(active)
	
	if not active: return
	
	for idx in script_tab.get_tab_count():
		script_tab.set_tab_title(idx, script_list_item.get_item_text(idx))
		script_tab.set_tab_icon(idx, script_list_item.get_item_icon(idx))
	
	if not script_tab.is_connected("tab_changed", self, "_editor_script_selected"):
		script_tab.connect("tab_changed", self, "_editor_script_selected")


func _editor_script_selected(idx: int = 0) -> void:
	script_list_item.select(idx)
	
	if dock.is_inside_tree():
		dock_tab.set_current_tab(dock.get_index())
	
	if menu_split.is_pressed():
		yield(get_tree(), "idle_frame")
		editor.set_main_screen_editor(menu_split_group.get_pressed_button()._get_tooltip())
		script_editor.show()
	else:
		editor.set_main_screen_editor(MAIN_EDITOR[ID_MAIN_EDITOR.SCRIPT])


func _connect_scripts_panel_toggle(_script: Script = null) -> void:
	var tab: Control = script_tab.get_current_tab_control()
	if not tab.get_child(0) is VSplitContainer: return
	
	var toggle: ToolButton = tab.get_child(0).get_child(0).get_child(2).get_child(0)
	if not toggle.is_connected("pressed", self, "_switch_script_list_dock"):
		toggle.connect("pressed", self, "_switch_script_list_dock")
	
	if menu_tab.is_pressed():
		var idx: int = script_tab.get_current_tab_control().get_index()
		script_tab.set_tab_title(idx, script_list_item.get_item_text(idx))
		script_tab.set_tab_icon(idx, script_list_item.get_item_icon(idx))


func _switch_script_list_dock() -> void:
	if _switching: return
	_switching = true
	
	if dock.is_inside_tree():
		dock_tab = dock.get_parent()
		dock.remove_child(script_list)
		script_container.add_child(script_list)
		script_container.move_child(script_list, 0)
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


func _create_menu() -> void:
	if menu_container.is_inside_tree(): return
	menu_split.set_toggle_mode(true)
	menu_split.set_text("Split")
	menu_split.hint_tooltip = "Split Mode.\nshare space with Script Editor "
	menu_split.hint_tooltip += "when selecting item in script panel outside script editor"
	
	menu_tab.set_toggle_mode(true)
	menu_tab.set_text("Tabs")
	menu_tab.set_tooltip("Show Script Editor Tabs") 
	
	menu_container.add_child(menu_tab)
	menu_container.add_child(menu_split)
	
	for idx in menu_split_editor.size():
		var tb: Button = menu_split_editor[idx]
		if not tb is Button: return
		tb.set_toggle_mode(true)
		tb.set_button_group(menu_split_group)
		tb.set_button_icon(script_menu.get_icon(MAIN_EDITOR[idx], "EditorIcons"))
		tb.set_tooltip(MAIN_EDITOR[idx])
		tb.set_pressed(true)
		tb.hide()
		tb.connect("pressed", editor, "set_main_screen_editor", [tb._get_tooltip()])
		menu_split.connect("toggled", tb, "set_visible")
		menu_container.add_child(tb)
	
	script_menu.add_child(menu_container)
	script_menu.move_child(menu_container, 3)
	
	menu_split.connect("pressed", self, "_editor_script_selected")
	menu_tab.connect("toggled", self, "_menu_tab_toggled")
	
	config_load()


func config_save() -> void:
	config.docked = dock.is_inside_tree()
	config.split_main = menu_split_group.get_pressed_button()._get_tooltip()
	
	var cfg := ConfigFile.new()
	for item in config.keys():
		cfg.set_value(PATH_CONFIG, item, config.get(item))
	
	cfg.save(PATH_CONFIG)


func config_load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH_CONFIG) != OK:
		_switch_script_list_dock()
		return
	
	for item in config.keys():
		config[item] = cfg.get_value(PATH_CONFIG, item, config.get(item))
	
	for button in menu_split_group.get_buttons():
		if button._get_tooltip() == config.split_main:
			button.pressed = true
			break
	
	editor.get_editor_settings().set(PATH_STAY_IN_SCRIPT, config.stay_in_scirpt)
	if not script_list.is_visible() or config.docked:
		_switch_script_list_dock()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░ Title: NV Script Editor
# ░░█▀█░█▀█░█░░░█░░░█░█░█▀▀░░ Act: Extend Script Editor Feature
# ░░█░█░█▀█░░▀▄░░▀▄░▀▄▀░█▀▀░░ Cast[ Editor, ScriptEditor ]
# ░░▀░▀░▀░▀░░░▀░░░▀░░▀░░▀▀▀░░ Writers[ @illlustr, ]
# ░ Projects ░░░░░░░░░░░░░░░░ https://github.com/naiiveprojects
