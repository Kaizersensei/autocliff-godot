@tool
extends VBoxContainer

class MeshPoolItemList:
	extends ItemList

	signal files_dropped(paths: PackedStringArray)

	var _supported_exts: PackedStringArray = PackedStringArray([
		".tscn", ".scn", ".obj", ".tres", ".res"
	])

	func set_supported_extensions(exts: PackedStringArray) -> void:
		_supported_exts = exts.duplicate()

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return not _extract_supported_paths(data).is_empty()

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		var supported: PackedStringArray = _extract_supported_paths(data)
		if supported.is_empty():
			return
		files_dropped.emit(supported)

	func _extract_supported_paths(data: Variant) -> PackedStringArray:
		var out: PackedStringArray = PackedStringArray()
		if typeof(data) == TYPE_DICTIONARY:
			var dict_data: Dictionary = data as Dictionary
			if dict_data.has("files"):
				var files_any: Variant = dict_data.get("files", PackedStringArray())
				if files_any is PackedStringArray:
					for path in (files_any as PackedStringArray):
						_try_append_supported(out, str(path))
				elif files_any is Array:
					for path_any in (files_any as Array):
						_try_append_supported(out, str(path_any))
		elif data is PackedStringArray:
			for path in (data as PackedStringArray):
				_try_append_supported(out, str(path))
		elif data is Array:
			for path_any in (data as Array):
				_try_append_supported(out, str(path_any))
		return out

	func _try_append_supported(out: PackedStringArray, raw_path: String) -> void:
		var path: String = raw_path.strip_edges()
		if path.is_empty():
			return
		if not path.begins_with("res://"):
			path = ProjectSettings.localize_path(path)
		if path.is_empty():
			return
		var lower_path: String = path.to_lower()
		for ext in _supported_exts:
			if lower_path.ends_with(ext):
				out.append(path)
				return

const ALL_COLLISION_LAYERS_MASK: int = 4294967295
const STATE_CFG_PATH: String = "user://densetsu_autocliff_state.cfg"
const STATE_SECTION: String = "autocliff"
const PRESET_DIR_PATH: String = "res://temp/autocliff_presets"
const PRESET_FILE_EXTENSION: String = ".cfg"
const BASE_PRESET_NAME: String = "base_floor_medium_cliff"
const LARGE_OBJECT_MIN_METERS: float = 15.0
const SMALL_OBJECT_MAX_METERS: float = 3.0
const BASE_MATERIAL_FILTER_LINEAR_MIPMAP_ANISO: int = 5
const SIZE_GROUP_LARGE: int = 0
const SIZE_GROUP_MEDIUM: int = 1
const SIZE_GROUP_SMALL: int = 2
const MATERIAL_FILTER_MODE_BASE_OR_OVERLAY: int = 0
const MATERIAL_FILTER_MODE_BASE_ONLY: int = 1
const MATERIAL_FILTER_MODE_OVERLAY_ONLY: int = 2
const MATERIAL_FILTER_MODE_DOMINANT: int = 3
var _supported_pool_extensions: PackedStringArray = PackedStringArray([
	".tscn", ".scn", ".obj", ".tres", ".res"
])

var _editor_interface: EditorInterface

var _target_path_edit: LineEdit
var _output_name_edit: LineEdit
var _preset_name_edit: LineEdit
var _preset_option: OptionButton
var _group_preview_label: Label
var _mesh_item_list: ItemList
var _status_label: Label
var _mesh_file_dialog: FileDialog

var _area_size_x_spin: SpinBox
var _area_size_z_spin: SpinBox
var _sample_spacing_spin: SpinBox
var _ray_height_spin: SpinBox
var _slope_min_spin: SpinBox
var _slope_max_spin: SpinBox
var _height_min_spin: SpinBox
var _height_max_spin: SpinBox
var _density_spin: SpinBox
var _bury_min_spin: SpinBox
var _bury_max_spin: SpinBox
var _scale_min_spin: SpinBox
var _scale_max_spin: SpinBox
var _yaw_jitter_spin: SpinBox
var _collision_mask_spin: SpinBox
var _clearance_radius_scale_spin: SpinBox
var _clearance_extra_spin: SpinBox
var _seed_spin: SpinBox
var _material_filter_id_spin: SpinBox
var _material_filter_mode_option: OptionButton

var _group_tuning_enabled_check: CheckBox
var _group_global_density_mult_spin: SpinBox
var _group_global_scale_mult_spin: SpinBox
var _group_global_bury_mult_spin: SpinBox
var _group_global_yaw_mult_spin: SpinBox
var _group_global_clearance_mult_spin: SpinBox
var _group_global_cluster_mult_spin: SpinBox

var _group_large_density_mult_spin: SpinBox
var _group_large_scale_mult_spin: SpinBox
var _group_large_bury_mult_spin: SpinBox
var _group_large_yaw_mult_spin: SpinBox
var _group_large_clearance_mult_spin: SpinBox
var _group_large_cluster_mult_spin: SpinBox
var _group_large_slope_min_spin: SpinBox
var _group_large_slope_max_spin: SpinBox

var _group_medium_density_mult_spin: SpinBox
var _group_medium_scale_mult_spin: SpinBox
var _group_medium_bury_mult_spin: SpinBox
var _group_medium_yaw_mult_spin: SpinBox
var _group_medium_clearance_mult_spin: SpinBox
var _group_medium_cluster_mult_spin: SpinBox
var _group_medium_slope_min_spin: SpinBox
var _group_medium_slope_max_spin: SpinBox

var _group_small_density_mult_spin: SpinBox
var _group_small_scale_mult_spin: SpinBox
var _group_small_bury_mult_spin: SpinBox
var _group_small_yaw_mult_spin: SpinBox
var _group_small_clearance_mult_spin: SpinBox
var _group_small_cluster_mult_spin: SpinBox
var _group_small_slope_min_spin: SpinBox
var _group_small_slope_max_spin: SpinBox

var _replace_existing_check: CheckBox
var _slope_order_check: CheckBox
var _use_multimesh_check: CheckBox
var _avoid_collider_overlap_check: CheckBox
var _avoid_static_aabb_overlap_check: CheckBox
var _avoid_cluster_overlap_check: CheckBox
var _clearance_check_areas_check: CheckBox
var _material_filter_enabled_check: CheckBox

var _pool_resources: Array[Resource] = []
var _pool_kinds: Array[String] = [] # "mesh" | "scene"
var _pool_paths: Array[String] = []
var _pool_bounds_sizes: Array[Vector3] = []
var _pool_bounds_radii: Array[float] = []
var _pool_preview_icons: Array[Texture2D] = []
var _pool_preview_requested: Dictionary = {}
var _state_loading: bool = false
var _save_queued: bool = false
var _filtered_material_cache: Dictionary = {}
var _filtered_mesh_cache: Dictionary = {}


func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_build_ui()
	_connect_persistence_signals()
	load_state()
	_ensure_base_preset_exists()
	_refresh_preset_options("")
	_update_group_preview()


func _build_ui() -> void:
	if get_child_count() > 0:
		return

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	var title: Label = Label.new()
	title.text = "Densetsu Autocliff"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var target_row: HBoxContainer = HBoxContainer.new()
	root.add_child(target_row)

	var target_label: Label = Label.new()
	target_label.text = "Target Surface"
	target_label.custom_minimum_size = Vector2(100.0, 0.0)
	target_row.add_child(target_label)

	_target_path_edit = LineEdit.new()
	_target_path_edit.placeholder_text = "Scene-relative Node3D path (Terrain3D or any collider-backed surface root)"
	_target_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_row.add_child(_target_path_edit)

	var use_selected_button: Button = Button.new()
	use_selected_button.text = "Use Selected"
	use_selected_button.pressed.connect(_on_use_selected_node_pressed)
	target_row.add_child(use_selected_button)

	var output_row: HBoxContainer = HBoxContainer.new()
	root.add_child(output_row)

	var output_label: Label = Label.new()
	output_label.text = "Output Root"
	output_label.custom_minimum_size = Vector2(100.0, 0.0)
	output_row.add_child(output_label)

	_output_name_edit = LineEdit.new()
	_output_name_edit.text = "Autocliff_Output"
	_output_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_row.add_child(_output_name_edit)

	var preset_row: HBoxContainer = HBoxContainer.new()
	root.add_child(preset_row)

	var preset_label: Label = Label.new()
	preset_label.text = "Preset"
	preset_label.custom_minimum_size = Vector2(100.0, 0.0)
	preset_row.add_child(preset_label)

	_preset_name_edit = LineEdit.new()
	_preset_name_edit.placeholder_text = "Preset name"
	_preset_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_row.add_child(_preset_name_edit)

	var preset_save_button: Button = Button.new()
	preset_save_button.text = "Save Preset"
	preset_save_button.pressed.connect(_on_save_preset_pressed)
	preset_row.add_child(preset_save_button)

	var preset_load_button: Button = Button.new()
	preset_load_button.text = "Load Preset"
	preset_load_button.pressed.connect(_on_load_preset_pressed)
	preset_row.add_child(preset_load_button)

	var preset_refresh_button: Button = Button.new()
	preset_refresh_button.text = "Refresh"
	preset_refresh_button.pressed.connect(_on_refresh_presets_pressed)
	preset_row.add_child(preset_refresh_button)

	var preset_reset_button: Button = Button.new()
	preset_reset_button.text = "Reset To Base"
	preset_reset_button.pressed.connect(_on_reset_to_base_preset_pressed)
	preset_row.add_child(preset_reset_button)

	_preset_option = OptionButton.new()
	_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_option.item_selected.connect(_on_preset_selected)
	root.add_child(_preset_option)

	var mesh_header: Label = Label.new()
	mesh_header.text = "Cliff Mesh Pool (ordered by slope when enabled)"
	root.add_child(mesh_header)

	_mesh_item_list = MeshPoolItemList.new()
	_mesh_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mesh_item_list.custom_minimum_size = Vector2(0.0, 160.0)
	_mesh_item_list.select_mode = ItemList.SELECT_MULTI
	_mesh_item_list.tooltip_text = "Drop .tscn/.scn/.obj/.tres/.res files here from FileSystem."
	var drop_item_list: MeshPoolItemList = _mesh_item_list as MeshPoolItemList
	if drop_item_list != null:
		drop_item_list.set_supported_extensions(_supported_pool_extensions)
		if not drop_item_list.files_dropped.is_connected(_on_mesh_files_selected):
			drop_item_list.files_dropped.connect(_on_mesh_files_selected)
	root.add_child(_mesh_item_list)

	_group_preview_label = Label.new()
	_group_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_group_preview_label.text = "Live Preview: no group data yet."
	root.add_child(_group_preview_label)

	var mesh_buttons: HBoxContainer = HBoxContainer.new()
	root.add_child(mesh_buttons)

	var add_files_button: Button = Button.new()
	add_files_button.text = "Add Mesh/Scene Files"
	add_files_button.pressed.connect(_on_add_mesh_files_pressed)
	mesh_buttons.add_child(add_files_button)

	var add_selected_mesh_button: Button = Button.new()
	add_selected_mesh_button.text = "Add Selected Assets"
	add_selected_mesh_button.pressed.connect(_on_add_selected_node_mesh_pressed)
	mesh_buttons.add_child(add_selected_mesh_button)

	var remove_mesh_button: Button = Button.new()
	remove_mesh_button.text = "Remove Selected"
	remove_mesh_button.pressed.connect(_on_remove_selected_meshes_pressed)
	mesh_buttons.add_child(remove_mesh_button)

	var clear_mesh_button: Button = Button.new()
	clear_mesh_button.text = "Clear"
	clear_mesh_button.pressed.connect(_on_clear_meshes_pressed)
	mesh_buttons.add_child(clear_mesh_button)

	var params_label: Label = Label.new()
	params_label.text = "Sampling And Placement"
	root.add_child(params_label)

	_area_size_x_spin = _add_spin_row(root, "Area Size X", 1.0, 8192.0, 1.0, 256.0)
	_area_size_z_spin = _add_spin_row(root, "Area Size Z", 1.0, 8192.0, 1.0, 256.0)
	_sample_spacing_spin = _add_spin_row(root, "Sample Spacing", 0.25, 128.0, 0.25, 4.0)
	_ray_height_spin = _add_spin_row(root, "Ray Half Height", 1.0, 4096.0, 1.0, 400.0)
	_slope_min_spin = _add_spin_row(root, "Slope Min (deg)", 0.0, 89.9, 0.1, 38.0)
	_slope_max_spin = _add_spin_row(root, "Slope Max (deg)", 0.0, 89.9, 0.1, 85.0)
	_height_min_spin = _add_spin_row(root, "Height Min (Y)", -100000.0, 100000.0, 0.1, -100000.0)
	_height_max_spin = _add_spin_row(root, "Height Max (Y)", -100000.0, 100000.0, 0.1, 100000.0)
	_density_spin = _add_spin_row(root, "Density (0-1)", 0.0, 1.0, 0.01, 0.55)
	_bury_min_spin = _add_spin_row(root, "Bury Min", 0.0, 10.0, 0.01, 0.2)
	_bury_max_spin = _add_spin_row(root, "Bury Max", 0.0, 10.0, 0.01, 0.8)
	_scale_min_spin = _add_spin_row(root, "Scale Min", 0.01, 64.0, 0.01, 0.9)
	_scale_max_spin = _add_spin_row(root, "Scale Max", 0.01, 64.0, 0.01, 1.2)
	_yaw_jitter_spin = _add_spin_row(root, "Yaw Jitter (deg)", 0.0, 180.0, 0.5, 15.0)
	_collision_mask_spin = _add_spin_row(root, "Collision Mask", 1.0, 4294967295.0, 1.0, 4294967295.0)
	_clearance_radius_scale_spin = _add_spin_row(root, "Clearance Radius Scale", 0.05, 4.0, 0.01, 1.0)
	_clearance_extra_spin = _add_spin_row(root, "Clearance Extra", 0.0, 64.0, 0.01, 0.1)
	_seed_spin = _add_spin_row(root, "Seed", 0.0, 2147483647.0, 1.0, 1337.0)
	_material_filter_id_spin = _add_spin_row(root, "Terrain Material ID", 0.0, 31.0, 1.0, 0.0)

	var material_mode_row: HBoxContainer = HBoxContainer.new()
	root.add_child(material_mode_row)
	var material_mode_label: Label = Label.new()
	material_mode_label.text = "Material Match Mode"
	material_mode_label.custom_minimum_size = Vector2(150.0, 0.0)
	material_mode_row.add_child(material_mode_label)
	_material_filter_mode_option = OptionButton.new()
	_material_filter_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_material_filter_mode_option.add_item("Base Or Overlay", MATERIAL_FILTER_MODE_BASE_OR_OVERLAY)
	_material_filter_mode_option.add_item("Base Only", MATERIAL_FILTER_MODE_BASE_ONLY)
	_material_filter_mode_option.add_item("Overlay Only", MATERIAL_FILTER_MODE_OVERLAY_ONLY)
	_material_filter_mode_option.add_item("Dominant Texture", MATERIAL_FILTER_MODE_DOMINANT)
	_material_filter_mode_option.selected = MATERIAL_FILTER_MODE_BASE_OR_OVERLAY
	material_mode_row.add_child(_material_filter_mode_option)

	var group_label: Label = Label.new()
	group_label.text = "Group Tuning (multiplies global values)"
	root.add_child(group_label)

	_group_tuning_enabled_check = _add_check_row(root, "Enable per-group multipliers", true)
	_group_global_density_mult_spin = _add_spin_row(root, "Global Density Mult", 0.0, 4.0, 0.01, 1.0)
	_group_global_scale_mult_spin = _add_spin_row(root, "Global Scale Mult", 0.01, 8.0, 0.01, 1.0)
	_group_global_bury_mult_spin = _add_spin_row(root, "Global Bury Mult", 0.0, 8.0, 0.01, 1.0)
	_group_global_yaw_mult_spin = _add_spin_row(root, "Global Yaw Mult", 0.0, 8.0, 0.01, 1.0)
	_group_global_clearance_mult_spin = _add_spin_row(root, "Global Clearance Mult", 0.01, 8.0, 0.01, 1.0)
	_group_global_cluster_mult_spin = _add_spin_row(root, "Global Cluster Avoid Mult", 0.01, 8.0, 0.01, 1.0)

	var large_label: Label = Label.new()
	large_label.text = "Large (>15m)"
	root.add_child(large_label)
	_group_large_density_mult_spin = _add_spin_row(root, "Large Density Mult", 0.0, 4.0, 0.01, 1.0)
	_group_large_scale_mult_spin = _add_spin_row(root, "Large Scale Mult", 0.01, 8.0, 0.01, 1.0)
	_group_large_bury_mult_spin = _add_spin_row(root, "Large Bury Mult", 0.0, 8.0, 0.01, 1.0)
	_group_large_yaw_mult_spin = _add_spin_row(root, "Large Yaw Mult", 0.0, 8.0, 0.01, 1.0)
	_group_large_clearance_mult_spin = _add_spin_row(root, "Large Clearance Mult", 0.01, 8.0, 0.01, 1.0)
	_group_large_cluster_mult_spin = _add_spin_row(root, "Large Cluster Avoid Mult", 0.01, 8.0, 0.01, 1.0)
	_group_large_slope_min_spin = _add_spin_row(root, "Large Slope Min (deg)", 0.0, 89.9, 0.1, 45.0)
	_group_large_slope_max_spin = _add_spin_row(root, "Large Slope Max (deg)", 0.0, 89.9, 0.1, 89.9)

	var medium_label: Label = Label.new()
	medium_label.text = "Medium (3m..15m)"
	root.add_child(medium_label)
	_group_medium_density_mult_spin = _add_spin_row(root, "Medium Density Mult", 0.0, 4.0, 0.01, 1.0)
	_group_medium_scale_mult_spin = _add_spin_row(root, "Medium Scale Mult", 0.01, 8.0, 0.01, 1.0)
	_group_medium_bury_mult_spin = _add_spin_row(root, "Medium Bury Mult", 0.0, 8.0, 0.01, 1.0)
	_group_medium_yaw_mult_spin = _add_spin_row(root, "Medium Yaw Mult", 0.0, 8.0, 0.01, 1.0)
	_group_medium_clearance_mult_spin = _add_spin_row(root, "Medium Clearance Mult", 0.01, 8.0, 0.01, 1.0)
	_group_medium_cluster_mult_spin = _add_spin_row(root, "Medium Cluster Avoid Mult", 0.01, 8.0, 0.01, 1.0)
	_group_medium_slope_min_spin = _add_spin_row(root, "Medium Slope Min (deg)", 0.0, 89.9, 0.1, 15.0)
	_group_medium_slope_max_spin = _add_spin_row(root, "Medium Slope Max (deg)", 0.0, 89.9, 0.1, 45.0)

	var small_label: Label = Label.new()
	small_label.text = "Small (<3m)"
	root.add_child(small_label)
	_group_small_density_mult_spin = _add_spin_row(root, "Small Density Mult", 0.0, 4.0, 0.01, 1.0)
	_group_small_scale_mult_spin = _add_spin_row(root, "Small Scale Mult", 0.01, 8.0, 0.01, 1.0)
	_group_small_bury_mult_spin = _add_spin_row(root, "Small Bury Mult", 0.0, 8.0, 0.01, 1.0)
	_group_small_yaw_mult_spin = _add_spin_row(root, "Small Yaw Mult", 0.0, 8.0, 0.01, 1.0)
	_group_small_clearance_mult_spin = _add_spin_row(root, "Small Clearance Mult", 0.01, 8.0, 0.01, 1.0)
	_group_small_cluster_mult_spin = _add_spin_row(root, "Small Cluster Avoid Mult", 0.01, 8.0, 0.01, 1.0)
	_group_small_slope_min_spin = _add_spin_row(root, "Small Slope Min (deg)", 0.0, 89.9, 0.1, 0.0)
	_group_small_slope_max_spin = _add_spin_row(root, "Small Slope Max (deg)", 0.0, 89.9, 0.1, 15.0)

	_replace_existing_check = _add_check_row(root, "Replace existing output with same name", true)
	_slope_order_check = _add_check_row(root, "Map slope to mesh list order", true)
	_use_multimesh_check = _add_check_row(root, "Use MultiMesh output (recommended)", true)
	if not _use_multimesh_check.toggled.is_connected(_on_use_multimesh_mode_toggled):
		_use_multimesh_check.toggled.connect(_on_use_multimesh_mode_toggled)
	_avoid_collider_overlap_check = _add_check_row(root, "Reject placements overlapping colliders", true)
	_avoid_static_aabb_overlap_check = _add_check_row(root, "Reject placements overlapping static mesh AABBs (no colliders required)", false)
	_avoid_cluster_overlap_check = _add_check_row(root, "Reject clustered placements (between generated items)", true)
	_clearance_check_areas_check = _add_check_row(root, "Treat Area3D as blockers", true)
	_material_filter_enabled_check = _add_check_row(root, "Generate only on selected Terrain3D material ID (Terrain3D only)", false)

	var actions: HBoxContainer = HBoxContainer.new()
	root.add_child(actions)

	var generate_button: Button = Button.new()
	generate_button.text = "Autocliff"
	generate_button.pressed.connect(_on_generate_pressed)
	actions.add_child(generate_button)

	var clear_button: Button = Button.new()
	clear_button.text = "Clear Generated"
	clear_button.pressed.connect(_on_clear_generated_pressed)
	actions.add_child(clear_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Ready."
	root.add_child(_status_label)

	_mesh_file_dialog = FileDialog.new()
	_mesh_file_dialog.title = "Add Cliff Mesh / Composite Scene Files"
	_mesh_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_mesh_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_mesh_file_dialog.filters = PackedStringArray([
		"*.tscn ; Godot Scene",
		"*.scn ; Imported Packed Scene",
		"*.obj ; OBJ Mesh",
		"*.tres ; TRES Resource",
		"*.res ; RES Resource"
	])
	_mesh_file_dialog.files_selected.connect(_on_mesh_files_selected)
	add_child(_mesh_file_dialog)


func _connect_persistence_signals() -> void:
	if _target_path_edit != null:
		if not _target_path_edit.text_changed.is_connected(_on_persist_text_changed):
			_target_path_edit.text_changed.connect(_on_persist_text_changed)
	if _output_name_edit != null:
		if not _output_name_edit.text_changed.is_connected(_on_persist_text_changed):
			_output_name_edit.text_changed.connect(_on_persist_text_changed)

	var spin_controls: Array[SpinBox] = [
		_area_size_x_spin, _area_size_z_spin, _sample_spacing_spin, _ray_height_spin,
		_slope_min_spin, _slope_max_spin, _height_min_spin, _height_max_spin, _density_spin, _bury_min_spin, _bury_max_spin,
		_scale_min_spin, _scale_max_spin, _yaw_jitter_spin, _collision_mask_spin,
		_clearance_radius_scale_spin, _clearance_extra_spin, _seed_spin, _material_filter_id_spin,
		_group_global_density_mult_spin, _group_global_scale_mult_spin, _group_global_bury_mult_spin,
		_group_global_yaw_mult_spin, _group_global_clearance_mult_spin, _group_global_cluster_mult_spin,
		_group_large_density_mult_spin, _group_large_scale_mult_spin, _group_large_bury_mult_spin,
		_group_large_yaw_mult_spin, _group_large_clearance_mult_spin, _group_large_cluster_mult_spin,
		_group_large_slope_min_spin, _group_large_slope_max_spin,
		_group_medium_density_mult_spin, _group_medium_scale_mult_spin, _group_medium_bury_mult_spin,
		_group_medium_yaw_mult_spin, _group_medium_clearance_mult_spin, _group_medium_cluster_mult_spin,
		_group_medium_slope_min_spin, _group_medium_slope_max_spin,
		_group_small_density_mult_spin, _group_small_scale_mult_spin, _group_small_bury_mult_spin,
		_group_small_yaw_mult_spin, _group_small_clearance_mult_spin, _group_small_cluster_mult_spin,
		_group_small_slope_min_spin, _group_small_slope_max_spin
	]
	for spin: SpinBox in spin_controls:
		if spin == null:
			continue
		if not spin.value_changed.is_connected(_on_persist_value_changed):
			spin.value_changed.connect(_on_persist_value_changed)

	var checks: Array[CheckBox] = [
		_group_tuning_enabled_check,
		_replace_existing_check, _slope_order_check, _use_multimesh_check,
		_avoid_collider_overlap_check, _avoid_static_aabb_overlap_check, _avoid_cluster_overlap_check, _clearance_check_areas_check,
		_material_filter_enabled_check
	]
	for check: CheckBox in checks:
		if check == null:
			continue
		if not check.toggled.is_connected(_on_persist_toggled):
			check.toggled.connect(_on_persist_toggled)

	if _material_filter_mode_option != null:
		if not _material_filter_mode_option.item_selected.is_connected(_on_persist_option_selected):
			_material_filter_mode_option.item_selected.connect(_on_persist_option_selected)


func _on_persist_text_changed(_value: String) -> void:
	_queue_save_state()
	_update_group_preview()


func _on_persist_value_changed(_value: float) -> void:
	_queue_save_state()
	_update_group_preview()


func _on_persist_toggled(_value: bool) -> void:
	_queue_save_state()
	_update_group_preview()


func _on_persist_option_selected(_index: int) -> void:
	_queue_save_state()
	_update_group_preview()


func _queue_save_state() -> void:
	if _state_loading:
		return
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_save_state_deferred")


func _save_state_deferred() -> void:
	_save_queued = false
	save_state()


func save_state() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value(STATE_SECTION, "target_path", _target_path_edit.text if _target_path_edit != null else "")
	cfg.set_value(STATE_SECTION, "output_name", _output_name_edit.text if _output_name_edit != null else "")

	_save_spin(cfg, "area_size_x", _area_size_x_spin)
	_save_spin(cfg, "area_size_z", _area_size_z_spin)
	_save_spin(cfg, "sample_spacing", _sample_spacing_spin)
	_save_spin(cfg, "ray_height", _ray_height_spin)
	_save_spin(cfg, "slope_min", _slope_min_spin)
	_save_spin(cfg, "slope_max", _slope_max_spin)
	_save_spin(cfg, "height_min", _height_min_spin)
	_save_spin(cfg, "height_max", _height_max_spin)
	_save_spin(cfg, "density", _density_spin)
	_save_spin(cfg, "bury_min", _bury_min_spin)
	_save_spin(cfg, "bury_max", _bury_max_spin)
	_save_spin(cfg, "scale_min", _scale_min_spin)
	_save_spin(cfg, "scale_max", _scale_max_spin)
	_save_spin(cfg, "yaw_jitter", _yaw_jitter_spin)
	_save_spin(cfg, "collision_mask", _collision_mask_spin)
	_save_spin(cfg, "clearance_radius_scale", _clearance_radius_scale_spin)
	_save_spin(cfg, "clearance_extra", _clearance_extra_spin)
	_save_spin(cfg, "seed", _seed_spin)
	_save_spin(cfg, "material_filter_id", _material_filter_id_spin)
	_save_spin(cfg, "group_global_density_mult", _group_global_density_mult_spin)
	_save_spin(cfg, "group_global_scale_mult", _group_global_scale_mult_spin)
	_save_spin(cfg, "group_global_bury_mult", _group_global_bury_mult_spin)
	_save_spin(cfg, "group_global_yaw_mult", _group_global_yaw_mult_spin)
	_save_spin(cfg, "group_global_clearance_mult", _group_global_clearance_mult_spin)
	_save_spin(cfg, "group_global_cluster_mult", _group_global_cluster_mult_spin)
	_save_spin(cfg, "group_large_density_mult", _group_large_density_mult_spin)
	_save_spin(cfg, "group_large_scale_mult", _group_large_scale_mult_spin)
	_save_spin(cfg, "group_large_bury_mult", _group_large_bury_mult_spin)
	_save_spin(cfg, "group_large_yaw_mult", _group_large_yaw_mult_spin)
	_save_spin(cfg, "group_large_clearance_mult", _group_large_clearance_mult_spin)
	_save_spin(cfg, "group_large_cluster_mult", _group_large_cluster_mult_spin)
	_save_spin(cfg, "group_large_slope_min", _group_large_slope_min_spin)
	_save_spin(cfg, "group_large_slope_max", _group_large_slope_max_spin)
	_save_spin(cfg, "group_medium_density_mult", _group_medium_density_mult_spin)
	_save_spin(cfg, "group_medium_scale_mult", _group_medium_scale_mult_spin)
	_save_spin(cfg, "group_medium_bury_mult", _group_medium_bury_mult_spin)
	_save_spin(cfg, "group_medium_yaw_mult", _group_medium_yaw_mult_spin)
	_save_spin(cfg, "group_medium_clearance_mult", _group_medium_clearance_mult_spin)
	_save_spin(cfg, "group_medium_cluster_mult", _group_medium_cluster_mult_spin)
	_save_spin(cfg, "group_medium_slope_min", _group_medium_slope_min_spin)
	_save_spin(cfg, "group_medium_slope_max", _group_medium_slope_max_spin)
	_save_spin(cfg, "group_small_density_mult", _group_small_density_mult_spin)
	_save_spin(cfg, "group_small_scale_mult", _group_small_scale_mult_spin)
	_save_spin(cfg, "group_small_bury_mult", _group_small_bury_mult_spin)
	_save_spin(cfg, "group_small_yaw_mult", _group_small_yaw_mult_spin)
	_save_spin(cfg, "group_small_clearance_mult", _group_small_clearance_mult_spin)
	_save_spin(cfg, "group_small_cluster_mult", _group_small_cluster_mult_spin)
	_save_spin(cfg, "group_small_slope_min", _group_small_slope_min_spin)
	_save_spin(cfg, "group_small_slope_max", _group_small_slope_max_spin)

	_save_check(cfg, "group_tuning_enabled", _group_tuning_enabled_check)
	_save_check(cfg, "replace_existing", _replace_existing_check)
	_save_check(cfg, "slope_order", _slope_order_check)
	_save_check(cfg, "use_multimesh", _use_multimesh_check)
	_save_check(cfg, "avoid_collider_overlap", _avoid_collider_overlap_check)
	_save_check(cfg, "avoid_static_aabb_overlap", _avoid_static_aabb_overlap_check)
	_save_check(cfg, "avoid_cluster_overlap", _avoid_cluster_overlap_check)
	_save_check(cfg, "clearance_check_areas", _clearance_check_areas_check)
	_save_check(cfg, "material_filter_enabled", _material_filter_enabled_check)
	cfg.set_value(STATE_SECTION, "material_filter_mode", _material_filter_mode_option.selected if _material_filter_mode_option != null else MATERIAL_FILTER_MODE_BASE_OR_OVERLAY)

	var pool_paths_to_save: PackedStringArray = PackedStringArray()
	var pool_kinds_to_save: PackedStringArray = PackedStringArray()
	for i: int in _pool_paths.size():
		var path: String = _pool_paths[i]
		var kind: String = _pool_kinds[i] if i < _pool_kinds.size() else ""
		if path.is_empty() or path.begins_with("<"):
			continue
		pool_paths_to_save.append(path)
		pool_kinds_to_save.append(kind)
	cfg.set_value(STATE_SECTION, "pool_paths", pool_paths_to_save)
	cfg.set_value(STATE_SECTION, "pool_kinds", pool_kinds_to_save)

	var err: Error = cfg.save(STATE_CFG_PATH)
	if err != OK:
		push_warning("Autocliff: failed to save state (%d)." % int(err))


func load_state() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(STATE_CFG_PATH)
	if err != OK:
		return
	_state_loading = true

	_set_line_edit_text(_target_path_edit, str(cfg.get_value(STATE_SECTION, "target_path", _target_path_edit.text if _target_path_edit != null else "")))
	_set_line_edit_text(_output_name_edit, str(cfg.get_value(STATE_SECTION, "output_name", _output_name_edit.text if _output_name_edit != null else "")))

	_load_spin(cfg, "area_size_x", _area_size_x_spin)
	_load_spin(cfg, "area_size_z", _area_size_z_spin)
	_load_spin(cfg, "sample_spacing", _sample_spacing_spin)
	_load_spin(cfg, "ray_height", _ray_height_spin)
	_load_spin(cfg, "slope_min", _slope_min_spin)
	_load_spin(cfg, "slope_max", _slope_max_spin)
	_load_spin(cfg, "height_min", _height_min_spin)
	_load_spin(cfg, "height_max", _height_max_spin)
	_load_spin(cfg, "density", _density_spin)
	_load_spin(cfg, "bury_min", _bury_min_spin)
	_load_spin(cfg, "bury_max", _bury_max_spin)
	_load_spin(cfg, "scale_min", _scale_min_spin)
	_load_spin(cfg, "scale_max", _scale_max_spin)
	_load_spin(cfg, "yaw_jitter", _yaw_jitter_spin)
	_load_spin(cfg, "collision_mask", _collision_mask_spin)
	_load_spin(cfg, "clearance_radius_scale", _clearance_radius_scale_spin)
	_load_spin(cfg, "clearance_extra", _clearance_extra_spin)
	_load_spin(cfg, "seed", _seed_spin)
	_load_spin(cfg, "material_filter_id", _material_filter_id_spin)
	_load_spin(cfg, "group_global_density_mult", _group_global_density_mult_spin)
	_load_spin(cfg, "group_global_scale_mult", _group_global_scale_mult_spin)
	_load_spin(cfg, "group_global_bury_mult", _group_global_bury_mult_spin)
	_load_spin(cfg, "group_global_yaw_mult", _group_global_yaw_mult_spin)
	_load_spin(cfg, "group_global_clearance_mult", _group_global_clearance_mult_spin)
	_load_spin(cfg, "group_global_cluster_mult", _group_global_cluster_mult_spin)
	_load_spin(cfg, "group_large_density_mult", _group_large_density_mult_spin)
	_load_spin(cfg, "group_large_scale_mult", _group_large_scale_mult_spin)
	_load_spin(cfg, "group_large_bury_mult", _group_large_bury_mult_spin)
	_load_spin(cfg, "group_large_yaw_mult", _group_large_yaw_mult_spin)
	_load_spin(cfg, "group_large_clearance_mult", _group_large_clearance_mult_spin)
	_load_spin(cfg, "group_large_cluster_mult", _group_large_cluster_mult_spin)
	_load_spin(cfg, "group_large_slope_min", _group_large_slope_min_spin)
	_load_spin(cfg, "group_large_slope_max", _group_large_slope_max_spin)
	_load_spin(cfg, "group_medium_density_mult", _group_medium_density_mult_spin)
	_load_spin(cfg, "group_medium_scale_mult", _group_medium_scale_mult_spin)
	_load_spin(cfg, "group_medium_bury_mult", _group_medium_bury_mult_spin)
	_load_spin(cfg, "group_medium_yaw_mult", _group_medium_yaw_mult_spin)
	_load_spin(cfg, "group_medium_clearance_mult", _group_medium_clearance_mult_spin)
	_load_spin(cfg, "group_medium_cluster_mult", _group_medium_cluster_mult_spin)
	_load_spin(cfg, "group_medium_slope_min", _group_medium_slope_min_spin)
	_load_spin(cfg, "group_medium_slope_max", _group_medium_slope_max_spin)
	_load_spin(cfg, "group_small_density_mult", _group_small_density_mult_spin)
	_load_spin(cfg, "group_small_scale_mult", _group_small_scale_mult_spin)
	_load_spin(cfg, "group_small_bury_mult", _group_small_bury_mult_spin)
	_load_spin(cfg, "group_small_yaw_mult", _group_small_yaw_mult_spin)
	_load_spin(cfg, "group_small_clearance_mult", _group_small_clearance_mult_spin)
	_load_spin(cfg, "group_small_cluster_mult", _group_small_cluster_mult_spin)
	_load_spin(cfg, "group_small_slope_min", _group_small_slope_min_spin)
	_load_spin(cfg, "group_small_slope_max", _group_small_slope_max_spin)

	_load_check(cfg, "group_tuning_enabled", _group_tuning_enabled_check)
	_load_check(cfg, "replace_existing", _replace_existing_check)
	_load_check(cfg, "slope_order", _slope_order_check)
	_load_check(cfg, "use_multimesh", _use_multimesh_check)
	_load_check(cfg, "avoid_collider_overlap", _avoid_collider_overlap_check)
	_load_check(cfg, "avoid_static_aabb_overlap", _avoid_static_aabb_overlap_check)
	_load_check(cfg, "avoid_cluster_overlap", _avoid_cluster_overlap_check)
	_load_check(cfg, "clearance_check_areas", _clearance_check_areas_check)
	_load_check(cfg, "material_filter_enabled", _material_filter_enabled_check)
	if _material_filter_mode_option != null and cfg.has_section_key(STATE_SECTION, "material_filter_mode"):
		var mode_value: int = _variant_to_int_or_default(cfg.get_value(STATE_SECTION, "material_filter_mode", MATERIAL_FILTER_MODE_BASE_OR_OVERLAY), MATERIAL_FILTER_MODE_BASE_OR_OVERLAY)
		_material_filter_mode_option.selected = clampi(mode_value, MATERIAL_FILTER_MODE_BASE_OR_OVERLAY, MATERIAL_FILTER_MODE_DOMINANT)

	_pool_resources.clear()
	_pool_kinds.clear()
	_pool_paths.clear()
	_pool_bounds_sizes.clear()
	_pool_bounds_radii.clear()
	_pool_preview_icons.clear()
	_pool_preview_requested.clear()
	var saved_paths_variant: Variant = cfg.get_value(STATE_SECTION, "pool_paths", PackedStringArray())
	var saved_kinds_variant: Variant = cfg.get_value(STATE_SECTION, "pool_kinds", PackedStringArray())
	var saved_paths: PackedStringArray = saved_paths_variant if saved_paths_variant is PackedStringArray else PackedStringArray()
	var saved_kinds: PackedStringArray = saved_kinds_variant if saved_kinds_variant is PackedStringArray else PackedStringArray()
	for i_path: int in saved_paths.size():
		var res_path: String = saved_paths[i_path]
		if res_path.is_empty():
			continue
		var res: Resource = ResourceLoader.load(res_path)
		if res == null:
			continue
		var kind: String = "mesh"
		if i_path < saved_kinds.size():
			kind = String(saved_kinds[i_path])
		if kind == "scene":
			var ps: PackedScene = res as PackedScene
			if ps != null:
				_append_scene(ps, res_path)
				continue
		var mesh_res: Mesh = res as Mesh
		if mesh_res != null:
			_append_mesh(mesh_res, res_path)
	_state_loading = false
	_refresh_mesh_list()
	_update_group_preview()


func _save_spin(cfg: ConfigFile, key: String, spin: SpinBox) -> void:
	if spin == null:
		return
	cfg.set_value(STATE_SECTION, key, spin.value)


func _save_check(cfg: ConfigFile, key: String, check: CheckBox) -> void:
	if check == null:
		return
	cfg.set_value(STATE_SECTION, key, check.button_pressed)


func _load_spin(cfg: ConfigFile, key: String, spin: SpinBox) -> void:
	if spin == null:
		return
	if not cfg.has_section_key(STATE_SECTION, key):
		return
	spin.value = float(cfg.get_value(STATE_SECTION, key, spin.value))


func _load_check(cfg: ConfigFile, key: String, check: CheckBox) -> void:
	if check == null:
		return
	if not cfg.has_section_key(STATE_SECTION, key):
		return
	check.button_pressed = bool(cfg.get_value(STATE_SECTION, key, check.button_pressed))


func _set_line_edit_text(line_edit: LineEdit, value: String) -> void:
	if line_edit == null:
		return
	line_edit.text = value


func _update_group_preview() -> void:
	if _group_preview_label == null:
		return
	if _pool_resources.is_empty():
		_group_preview_label.text = "Live Preview: add meshes/scenes to see group distribution."
		return
	_ensure_pool_metadata()
	var large_count: int = 0
	var medium_count: int = 0
	var small_count: int = 0
	for i: int in _pool_resources.size():
		var group_id: int = _get_size_group_id(_get_pool_entry_effective_longest_side_meters(i))
		if group_id == SIZE_GROUP_LARGE:
			large_count += 1
		elif group_id == SIZE_GROUP_SMALL:
			small_count += 1
		else:
			medium_count += 1

	var global_density_mult: float = _group_global_density_mult_spin.value if _group_global_density_mult_spin != null else 1.0
	var global_cluster_mult: float = _group_global_cluster_mult_spin.value if _group_global_cluster_mult_spin != null else 1.0
	var use_group_tuning: bool = _group_tuning_enabled_check != null and _group_tuning_enabled_check.button_pressed
	var use_cluster_avoidance: bool = _avoid_cluster_overlap_check != null and _avoid_cluster_overlap_check.button_pressed
	var use_material_filter: bool = _material_filter_enabled_check != null and _material_filter_enabled_check.button_pressed
	var material_id: int = int(_material_filter_id_spin.value) if _material_filter_id_spin != null else 0
	var material_mode_label: String = "Base Or Overlay"
	if _material_filter_mode_option != null:
		material_mode_label = _material_filter_mode_option.get_item_text(_material_filter_mode_option.selected)

	var large_density: float = global_density_mult
	var medium_density: float = global_density_mult
	var small_density: float = global_density_mult
	var large_cluster: float = global_cluster_mult
	var medium_cluster: float = global_cluster_mult
	var small_cluster: float = global_cluster_mult
	if use_group_tuning:
		large_density *= _group_large_density_mult_spin.value if _group_large_density_mult_spin != null else 1.0
		medium_density *= _group_medium_density_mult_spin.value if _group_medium_density_mult_spin != null else 1.0
		small_density *= _group_small_density_mult_spin.value if _group_small_density_mult_spin != null else 1.0
		large_cluster *= _group_large_cluster_mult_spin.value if _group_large_cluster_mult_spin != null else 1.0
		medium_cluster *= _group_medium_cluster_mult_spin.value if _group_medium_cluster_mult_spin != null else 1.0
		small_cluster *= _group_small_cluster_mult_spin.value if _group_small_cluster_mult_spin != null else 1.0

	_group_preview_label.text = (
		"Live Preview: entries L/M/S = %d/%d/%d | Group tuning: %s | Cluster avoidance: %s | Material filter: %s\n"
		+ "Effective density mult L/M/S = %.2f / %.2f / %.2f\n"
		+ "Effective cluster avoid mult L/M/S = %.2f / %.2f / %.2f\n"
		+ "Material target: ID %d (%s)"
	) % [
		large_count, medium_count, small_count,
		"ON" if use_group_tuning else "OFF",
		"ON" if use_cluster_avoidance else "OFF",
		"ON" if use_material_filter else "OFF",
		large_density, medium_density, small_density,
		large_cluster, medium_cluster, small_cluster,
		material_id, material_mode_label
	]


func _ensure_preset_dir() -> bool:
	var absolute_dir: String = ProjectSettings.globalize_path(PRESET_DIR_PATH)
	var err: Error = DirAccess.make_dir_recursive_absolute(absolute_dir)
	return err == OK


func _sanitize_preset_name(name: String) -> String:
	var cleaned: String = name.strip_edges()
	cleaned = cleaned.replace(" ", "_")
	cleaned = cleaned.replace("/", "_")
	cleaned = cleaned.replace("\\", "_")
	cleaned = cleaned.replace(":", "_")
	cleaned = cleaned.replace("*", "_")
	cleaned = cleaned.replace("?", "_")
	cleaned = cleaned.replace("\"", "_")
	cleaned = cleaned.replace("<", "_")
	cleaned = cleaned.replace(">", "_")
	cleaned = cleaned.replace("|", "_")
	return cleaned


func _preset_path_from_name(preset_name: String) -> String:
	return "%s/%s%s" % [PRESET_DIR_PATH, preset_name, PRESET_FILE_EXTENSION]


func _refresh_preset_options(selected_name: String = "") -> void:
	if _preset_option == null:
		return
	_ensure_preset_dir()
	var names: Array[String] = []
	var dir: DirAccess = DirAccess.open(PRESET_DIR_PATH)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var file_name: String = dir.get_next()
			if file_name.is_empty():
				break
			if dir.current_is_dir():
				continue
			if file_name.to_lower().ends_with(PRESET_FILE_EXTENSION):
				names.append(file_name.substr(0, file_name.length() - PRESET_FILE_EXTENSION.length()))
		dir.list_dir_end()
	names.sort()

	_preset_option.clear()
	for preset_name: String in names:
		_preset_option.add_item(preset_name)

	if _preset_option.item_count <= 0:
		return

	var resolved_name: String = selected_name.strip_edges()
	if resolved_name.is_empty() and _preset_name_edit != null:
		resolved_name = _preset_name_edit.text.strip_edges()
	var target_index: int = -1
	for i: int in _preset_option.item_count:
		if _preset_option.get_item_text(i) == resolved_name:
			target_index = i
			break
	if target_index < 0:
		target_index = 0
	_preset_option.select(target_index)
	if _preset_name_edit != null:
		_preset_name_edit.text = _preset_option.get_item_text(target_index)


func _get_selected_preset_name() -> String:
	if _preset_option != null:
		var idx: int = _preset_option.get_selected_id()
		if idx < 0:
			idx = _preset_option.selected
		if idx >= 0 and idx < _preset_option.item_count:
			return _preset_option.get_item_text(idx)
	if _preset_name_edit != null:
		return _preset_name_edit.text.strip_edges()
	return ""


func _on_preset_selected(index: int) -> void:
	if _preset_option == null or _preset_name_edit == null:
		return
	if index < 0 or index >= _preset_option.item_count:
		return
	_preset_name_edit.text = _preset_option.get_item_text(index)


func _on_save_preset_pressed() -> void:
	var raw_name: String = _preset_name_edit.text if _preset_name_edit != null else ""
	var preset_name: String = _sanitize_preset_name(raw_name)
	if preset_name.is_empty():
		_set_status("Autocliff: enter a preset name first.", true)
		return
	if not _ensure_preset_dir():
		_set_status("Autocliff: failed to create preset directory.", true)
		return
	save_state()
	var dst_path: String = _preset_path_from_name(preset_name)
	if not _copy_file_bytes(STATE_CFG_PATH, dst_path):
		_set_status("Autocliff: failed to save preset '%s'." % preset_name, true)
		return
	_refresh_preset_options(preset_name)
	_set_status("Autocliff: preset saved '%s'." % preset_name, false)


func _on_load_preset_pressed() -> void:
	var preset_name: String = _sanitize_preset_name(_get_selected_preset_name())
	if preset_name.is_empty():
		_set_status("Autocliff: choose a preset first.", true)
		return
	_load_preset_by_name(preset_name, true)


func _on_refresh_presets_pressed() -> void:
	_refresh_preset_options(_sanitize_preset_name(_get_selected_preset_name()))
	_set_status("Autocliff: preset list refreshed.", false)


func _on_reset_to_base_preset_pressed() -> void:
	if not _ensure_base_preset_exists():
		_set_status("Autocliff: failed to create base preset.", true)
		return
	_load_preset_by_name(BASE_PRESET_NAME, true)


func _load_preset_by_name(preset_name: String, set_status: bool) -> void:
	var preset_path: String = _preset_path_from_name(preset_name)
	if not FileAccess.file_exists(preset_path):
		if set_status:
			_set_status("Autocliff: preset not found '%s'." % preset_name, true)
		return
	if not _copy_file_bytes(preset_path, STATE_CFG_PATH):
		if set_status:
			_set_status("Autocliff: failed to load preset '%s'." % preset_name, true)
		return
	load_state()
	_refresh_preset_options(preset_name)
	if set_status:
		_set_status("Autocliff: preset loaded '%s'." % preset_name, false)


func _copy_file_bytes(src_path: String, dst_path: String) -> bool:
	if not FileAccess.file_exists(src_path):
		return false
	var data: PackedByteArray = FileAccess.get_file_as_bytes(src_path)
	var file: FileAccess = FileAccess.open(dst_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(data)
	file.flush()
	return true


func _ensure_base_preset_exists() -> bool:
	if not _ensure_preset_dir():
		return false
	var base_path: String = _preset_path_from_name(BASE_PRESET_NAME)
	if FileAccess.file_exists(base_path):
		return true
	save_state()
	var cfg: ConfigFile = ConfigFile.new()
	var load_err: Error = cfg.load(STATE_CFG_PATH)
	if load_err != OK:
		return false
	cfg.set_value(STATE_SECTION, "group_tuning_enabled", true)
	cfg.set_value(STATE_SECTION, "height_min", -100000.0)
	cfg.set_value(STATE_SECTION, "height_max", 100000.0)
	cfg.set_value(STATE_SECTION, "avoid_static_aabb_overlap", false)
	cfg.set_value(STATE_SECTION, "material_filter_enabled", false)
	cfg.set_value(STATE_SECTION, "material_filter_id", 0.0)
	cfg.set_value(STATE_SECTION, "material_filter_mode", MATERIAL_FILTER_MODE_BASE_OR_OVERLAY)
	cfg.set_value(STATE_SECTION, "group_small_slope_min", 0.0)
	cfg.set_value(STATE_SECTION, "group_small_slope_max", 15.0)
	cfg.set_value(STATE_SECTION, "group_medium_slope_min", 15.0)
	cfg.set_value(STATE_SECTION, "group_medium_slope_max", 45.0)
	cfg.set_value(STATE_SECTION, "group_large_slope_min", 45.0)
	cfg.set_value(STATE_SECTION, "group_large_slope_max", 89.9)
	cfg.set_value(STATE_SECTION, "group_global_cluster_mult", 1.0)
	cfg.set_value(STATE_SECTION, "group_large_cluster_mult", 1.0)
	cfg.set_value(STATE_SECTION, "group_medium_cluster_mult", 1.0)
	cfg.set_value(STATE_SECTION, "group_small_cluster_mult", 1.0)
	return cfg.save(base_path) == OK


func _on_use_multimesh_mode_toggled(enabled: bool) -> void:
	if _state_loading:
		return
	var output_root: Node3D = _get_autocliff_output_root()
	if output_root == null:
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root() if _editor_interface != null else null
	if scene_root == null:
		return
	if enabled:
		var baked_count: int = _convert_output_to_multimesh(output_root, scene_root)
		if baked_count > 0:
			_set_status("Autocliff: baked existing output to MultiMesh nodes (%d groups)." % baked_count, false)
	else:
		var expanded_count: int = _convert_output_to_arraymesh_groups(output_root, scene_root)
		if expanded_count > 0:
			_set_status("Autocliff: expanded MultiMesh output to ArrayMesh groups (%d groups)." % expanded_count, false)


func _get_autocliff_output_root() -> Node3D:
	if _editor_interface == null:
		return null
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		return null
	var target_path_text: String = _target_path_edit.text.strip_edges() if _target_path_edit != null else ""
	if target_path_text.is_empty():
		return null
	var target_any: Node = scene_root.get_node_or_null(NodePath(target_path_text))
	if not _is_valid_target_node(target_any):
		return null
	var target_node: Node3D = target_any as Node3D
	if target_node == null:
		return null
	var output_parent: Node = target_node.get_parent()
	if output_parent == null:
		output_parent = scene_root
	var output_name: String = _output_name_edit.text.strip_edges() if _output_name_edit != null else ""
	if output_name.is_empty():
		output_name = "Autocliff_%s" % target_node.name
	return output_parent.get_node_or_null(NodePath(output_name)) as Node3D


func _mesh_group_key(mesh: Mesh) -> String:
	if mesh == null:
		return ""
	if not mesh.resource_path.is_empty():
		return mesh.resource_path
	return "mesh_%d" % mesh.get_instance_id()


func _convert_output_to_multimesh(output_root: Node3D, scene_root: Node) -> int:
	_reset_filter_fix_caches()
	var grouped: Dictionary = {}
	var mesh_nodes: Array[MeshInstance3D] = []
	for child in output_root.get_children():
		var mesh_node: MeshInstance3D = child as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			continue
		mesh_nodes.append(mesh_node)
		var key: String = _mesh_group_key(mesh_node.mesh)
		if not grouped.has(key):
			grouped[key] = {"mesh": mesh_node.mesh, "transforms": []}
		var entry: Dictionary = grouped[key]
		var transforms: Array = entry.get("transforms", [])
		transforms.append(mesh_node.transform)
		entry["transforms"] = transforms
		grouped[key] = entry
	if mesh_nodes.is_empty():
		return 0

	for mesh_node: MeshInstance3D in mesh_nodes:
		output_root.remove_child(mesh_node)
		mesh_node.queue_free()

	var created_groups: int = 0
	var used_names: Dictionary = {}
	for key_variant: Variant in grouped.keys():
		var key: String = str(key_variant)
		var entry: Dictionary = grouped.get(key, {})
		var mesh: Mesh = entry.get("mesh", null) as Mesh
		var transforms: Array = entry.get("transforms", [])
		if mesh == null or transforms.is_empty():
			continue
		var filtered_mesh: Mesh = _get_filtered_mesh_for_output(mesh)
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = filtered_mesh
		mm.instance_count = transforms.size()
		for i_tf: int in transforms.size():
			var local_xf: Transform3D = transforms[i_tf]
			mm.set_instance_transform(i_tf, local_xf)

		var mm_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		var base_name: String = _get_pool_entry_base_name(-1, mesh)
		mm_instance.name = _make_unique_name("%s_MM_Baked" % base_name, used_names)
		mm_instance.multimesh = mm
		output_root.add_child(mm_instance)
		mm_instance.owner = scene_root
		created_groups += 1
	return created_groups


func _convert_output_to_arraymesh_groups(output_root: Node3D, scene_root: Node) -> int:
	_reset_filter_fix_caches()
	var mm_nodes: Array[MultiMeshInstance3D] = []
	for child in output_root.get_children():
		var mm_node: MultiMeshInstance3D = child as MultiMeshInstance3D
		if mm_node == null:
			continue
		if mm_node.multimesh == null or mm_node.multimesh.mesh == null:
			continue
		mm_nodes.append(mm_node)
	if mm_nodes.is_empty():
		return 0

	var created_groups: int = 0
	var used_names: Dictionary = {}
	for mm_node: MultiMeshInstance3D in mm_nodes:
		var mm: MultiMesh = mm_node.multimesh
		var base_name: String = _get_pool_entry_base_name(-1, mm.mesh)
		var group_root: Node3D = Node3D.new()
		group_root.name = _make_unique_name("%s_Group" % base_name, used_names)
		output_root.add_child(group_root)
		group_root.owner = scene_root

		var i_tf: int = 0
		while i_tf < mm.instance_count:
			var mesh_instance: MeshInstance3D = MeshInstance3D.new()
			mesh_instance.name = _make_unique_name(base_name, used_names)
			mesh_instance.mesh = _get_filtered_mesh_for_output(mm.mesh)
			mesh_instance.transform = mm.get_instance_transform(i_tf)
			_apply_filter_to_mesh_instance_materials(mesh_instance)
			group_root.add_child(mesh_instance)
			mesh_instance.owner = scene_root
			i_tf += 1

		output_root.remove_child(mm_node)
		mm_node.queue_free()
		created_groups += 1
	return created_groups


func _placement_overlaps_generated_cluster(
	world_position: Vector3,
	radius: float,
	existing_positions: Array[Vector3],
	existing_radii: Array[float]
) -> bool:
	var safe_radius: float = maxf(0.01, radius)
	var i: int = 0
	while i < existing_positions.size():
		var other_position: Vector3 = existing_positions[i]
		var other_radius: float = existing_radii[i] if i < existing_radii.size() else safe_radius
		var min_dist: float = safe_radius + maxf(0.01, other_radius)
		if world_position.distance_squared_to(other_position) < min_dist * min_dist:
			return true
		i += 1
	return false


func _add_spin_row(parent: VBoxContainer, label_text: String, min_val: float, max_val: float, step: float, default_val: float) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150.0, 0.0)
	row.add_child(label)

	var spin: SpinBox = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = default_val
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spin)
	return spin


func _add_check_row(parent: VBoxContainer, label_text: String, default_value: bool) -> CheckBox:
	var check: CheckBox = CheckBox.new()
	check.text = label_text
	check.button_pressed = default_value
	parent.add_child(check)
	return check


func _on_use_selected_node_pressed() -> void:
	var selected: Node3D = _get_first_selected_target_node()
	if selected == null:
		_set_status("Autocliff: select a Node3D target in the Scene tree first.", true)
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		_set_status("Autocliff: no edited scene root.", true)
		return
	var rel_path: NodePath = scene_root.get_path_to(selected)
	_target_path_edit.text = String(rel_path)
	if _output_name_edit.text.strip_edges().is_empty():
		_output_name_edit.text = "Autocliff_%s" % selected.name
	_set_status("Autocliff target set: %s" % _target_path_edit.text, false)


func _on_add_selected_node_mesh_pressed() -> void:
	var selected_paths: PackedStringArray = _get_filesystem_selection_paths()
	if selected_paths.is_empty():
		_set_status("Autocliff: select mesh/scene assets in the FileSystem dock first.", true)
		return
	var filtered_paths: PackedStringArray = PackedStringArray()
	for raw_path in selected_paths:
		var path: String = _normalize_to_res_path(str(raw_path))
		if path.is_empty():
			continue
		if _is_supported_pool_path(path):
			filtered_paths.append(path)
	if filtered_paths.is_empty():
		_set_status("Autocliff: FileSystem selection has no supported mesh/scene assets.", true)
		return
	_on_mesh_files_selected(filtered_paths)


func _on_add_mesh_files_pressed() -> void:
	_mesh_file_dialog.popup_centered_ratio(0.5)


func _on_mesh_files_selected(paths: PackedStringArray) -> void:
	var added: int = 0
	var skipped: int = 0
	for raw_path in paths:
		var path: String = _normalize_to_res_path(str(raw_path))
		if path.is_empty() or not _is_supported_pool_path(path):
			skipped += 1
			continue
		var resource: Resource = ResourceLoader.load(path)
		var packed_scene: PackedScene = resource as PackedScene
		if packed_scene != null:
			if _append_scene(packed_scene, path):
				added += 1
			else:
				skipped += 1
			continue
		var mesh: Mesh = resource as Mesh
		if mesh == null:
			skipped += 1
			continue
		if _append_mesh(mesh, path):
			added += 1
		else:
			skipped += 1
	_set_status("Autocliff: added %d mesh(es), skipped %d." % [added, skipped], false)


func _append_mesh(mesh: Mesh, source_label: String) -> bool:
	return _append_pool_entry(mesh, "mesh", source_label)


func _append_scene(scene: PackedScene, source_label: String) -> bool:
	return _append_pool_entry(scene, "scene", source_label)


func _append_pool_entry(resource: Resource, kind: String, source_label: String) -> bool:
	if resource == null:
		return false
	var i: int = 0
	while i < _pool_resources.size():
		if _pool_resources[i] == resource:
			return false
		if _pool_paths[i] == source_label and _pool_kinds[i] == kind:
			return false
		i += 1
	var bounds_info: Dictionary = _compute_pool_entry_bounds(resource, kind)
	var bounds_size_variant: Variant = bounds_info.get("size", Vector3.ONE)
	var bounds_radius_variant: Variant = bounds_info.get("radius", 0.5)
	var bounds_size: Vector3 = bounds_size_variant if bounds_size_variant is Vector3 else Vector3.ONE
	var bounds_radius: float = float(bounds_radius_variant)
	_pool_resources.append(resource)
	_pool_kinds.append(kind)
	_pool_paths.append(source_label)
	_pool_bounds_sizes.append(bounds_size)
	_pool_bounds_radii.append(maxf(0.01, bounds_radius))
	_pool_preview_icons.append(null)
	_refresh_mesh_list()
	_queue_save_state()
	return true


func _on_remove_selected_meshes_pressed() -> void:
	var selected_indices: PackedInt32Array = _mesh_item_list.get_selected_items()
	if selected_indices.is_empty():
		return
	var indices: Array[int] = []
	for idx in selected_indices:
		indices.append(idx)
	indices.sort()
	indices.reverse()
	for idx in indices:
		if idx >= 0 and idx < _pool_resources.size():
			_pool_resources.remove_at(idx)
			_pool_kinds.remove_at(idx)
			_pool_paths.remove_at(idx)
			if idx < _pool_bounds_sizes.size():
				_pool_bounds_sizes.remove_at(idx)
			if idx < _pool_bounds_radii.size():
				_pool_bounds_radii.remove_at(idx)
			if idx < _pool_preview_icons.size():
				_pool_preview_icons.remove_at(idx)
	_refresh_mesh_list()
	_set_status("Autocliff: removed selected pool entries.", false)
	_queue_save_state()


func _on_clear_meshes_pressed() -> void:
	_pool_resources.clear()
	_pool_kinds.clear()
	_pool_paths.clear()
	_pool_bounds_sizes.clear()
	_pool_bounds_radii.clear()
	_pool_preview_icons.clear()
	_pool_preview_requested.clear()
	_refresh_mesh_list()
	_set_status("Autocliff: cliff pool cleared.", false)
	_queue_save_state()


func _refresh_mesh_list() -> void:
	_mesh_item_list.clear()
	_ensure_pool_metadata()
	var i: int = 0
	while i < _pool_paths.size():
		var label: String = _pool_paths[i]
		if label.is_empty():
			label = "<entry_%d>" % i
		var kind: String = _pool_kinds[i] if i < _pool_kinds.size() else "?"
		var prefix: String = "[Mesh]"
		if kind == "scene":
			prefix = "[Scene]"
		var size_vec: Vector3 = _pool_bounds_sizes[i] if i < _pool_bounds_sizes.size() else Vector3.ONE
		var longest_side_m: float = _get_pool_entry_effective_longest_side_meters(i)
		var size_group: String = _get_size_group_name(longest_side_m)
		var size_text: String = "%.2f x %.2f x %.2f m (eff max side %.2f m)" % [size_vec.x, size_vec.y, size_vec.z, longest_side_m]
		_mesh_item_list.add_item("%d. %s %s | %s | %s" % [i + 1, prefix, label, size_group, size_text])
		i += 1
	_update_group_preview()


func _ensure_pool_metadata() -> void:
	var target_count: int = _pool_resources.size()
	while _pool_bounds_sizes.size() < target_count:
		var idx: int = _pool_bounds_sizes.size()
		var resource: Resource = _pool_resources[idx]
		var kind: String = _pool_kinds[idx] if idx < _pool_kinds.size() else "mesh"
		var bounds_info: Dictionary = _compute_pool_entry_bounds(resource, kind)
		var bounds_size_variant: Variant = bounds_info.get("size", Vector3.ONE)
		var bounds_radius_variant: Variant = bounds_info.get("radius", 0.5)
		var bounds_size: Vector3 = bounds_size_variant if bounds_size_variant is Vector3 else Vector3.ONE
		var bounds_radius: float = float(bounds_radius_variant)
		_pool_bounds_sizes.append(bounds_size)
		_pool_bounds_radii.append(maxf(0.01, bounds_radius))
	while _pool_bounds_radii.size() < target_count:
		_pool_bounds_radii.append(0.5)
	while _pool_preview_icons.size() < target_count:
		_pool_preview_icons.append(null)
	while _pool_bounds_sizes.size() > target_count:
		_pool_bounds_sizes.remove_at(_pool_bounds_sizes.size() - 1)
	while _pool_bounds_radii.size() > target_count:
		_pool_bounds_radii.remove_at(_pool_bounds_radii.size() - 1)
	while _pool_preview_icons.size() > target_count:
		_pool_preview_icons.remove_at(_pool_preview_icons.size() - 1)


func _get_pool_entry_longest_side_meters(index: int) -> float:
	if index < 0 or index >= _pool_resources.size():
		return 1.0
	_ensure_pool_metadata()
	var bounds_size: Vector3 = _pool_bounds_sizes[index] if index < _pool_bounds_sizes.size() else Vector3.ONE
	var side_xy: float = maxf(bounds_size.x, bounds_size.y)
	return maxf(side_xy, bounds_size.z)


func _get_scale_max_for_grouping() -> float:
	var scale_min_value: float = _scale_min_spin.value if _scale_min_spin != null else 1.0
	var scale_max_value: float = _scale_max_spin.value if _scale_max_spin != null else 1.0
	return maxf(scale_min_value, scale_max_value)


func _get_global_scale_mult_for_grouping() -> float:
	return maxf(0.01, _group_global_scale_mult_spin.value if _group_global_scale_mult_spin != null else 1.0)


func _get_group_scale_mult_for_grouping(group_id: int, use_group_tuning: bool) -> float:
	if not use_group_tuning:
		return 1.0
	return _get_group_spin_multiplier(
		group_id,
		_group_large_scale_mult_spin,
		_group_medium_scale_mult_spin,
		_group_small_scale_mult_spin
	)


func _get_pool_entry_effective_longest_side_meters(index: int) -> float:
	var base_longest: float = _get_pool_entry_longest_side_meters(index)
	var use_group_tuning: bool = _group_tuning_enabled_check != null and _group_tuning_enabled_check.button_pressed
	var scale_max_value: float = _get_scale_max_for_grouping()
	var global_scale_mult: float = _get_global_scale_mult_for_grouping()
	var group_id: int = _get_size_group_id(base_longest)
	var iter: int = 0
	while iter < 3:
		var group_scale_mult: float = _get_group_scale_mult_for_grouping(group_id, use_group_tuning)
		var effective_longest: float = base_longest * scale_max_value * global_scale_mult * group_scale_mult
		var next_group_id: int = _get_size_group_id(effective_longest)
		if next_group_id == group_id:
			return effective_longest
		group_id = next_group_id
		iter += 1
	var final_group_scale_mult: float = _get_group_scale_mult_for_grouping(group_id, use_group_tuning)
	return base_longest * scale_max_value * global_scale_mult * final_group_scale_mult


func _get_size_group_name(longest_side_m: float) -> String:
	if longest_side_m > LARGE_OBJECT_MIN_METERS:
		return "Large (>15m)"
	if longest_side_m < SMALL_OBJECT_MAX_METERS:
		return "Small (<3m)"
	return "Medium (3m..15m)"


func _get_size_group_id(longest_side_m: float) -> int:
	if longest_side_m > LARGE_OBJECT_MIN_METERS:
		return SIZE_GROUP_LARGE
	if longest_side_m < SMALL_OBJECT_MAX_METERS:
		return SIZE_GROUP_SMALL
	return SIZE_GROUP_MEDIUM


func _get_group_spin_multiplier(group_id: int, large_spin: SpinBox, medium_spin: SpinBox, small_spin: SpinBox) -> float:
	var value: float = 1.0
	if group_id == SIZE_GROUP_LARGE:
		if large_spin != null:
			value = large_spin.value
	elif group_id == SIZE_GROUP_SMALL:
		if small_spin != null:
			value = small_spin.value
	else:
		if medium_spin != null:
			value = medium_spin.value
	return maxf(0.0, value)


func _get_pool_entry_base_name(index: int, entry_res: Resource = null) -> String:
	var base_name: String = ""
	if index >= 0 and index < _pool_paths.size():
		var label: String = str(_pool_paths[index]).strip_edges()
		if not label.is_empty():
			base_name = label.get_file().get_basename()
	if base_name.is_empty() and entry_res != null:
		var res_path: String = str(entry_res.resource_path).strip_edges()
		if not res_path.is_empty():
			base_name = res_path.get_file().get_basename()
	if base_name.is_empty() and entry_res != null:
		base_name = str(entry_res.resource_name).strip_edges()
	if base_name.is_empty():
		base_name = "Cliff"
	base_name = base_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	base_name = base_name.strip_edges()
	if base_name.is_empty():
		base_name = "Cliff"
	return base_name


func _make_unique_name(base_name: String, used_names: Dictionary) -> String:
	var safe_base: String = base_name.strip_edges()
	if safe_base.is_empty():
		safe_base = "Cliff"
	var next_index: int = int(used_names.get(safe_base, 0))
	var out_name: String = safe_base
	if next_index > 0:
		out_name = "%s_%d" % [safe_base, next_index]
	used_names[safe_base] = next_index + 1
	return out_name


func _build_generation_order_indices(entry_count: int) -> Array[int]:
	var large_indices: Array[int] = []
	var medium_indices: Array[int] = []
	var small_indices: Array[int] = []
	var idx: int = 0
	while idx < entry_count:
		var longest_side_m: float = _get_pool_entry_effective_longest_side_meters(idx)
		if longest_side_m > LARGE_OBJECT_MIN_METERS:
			large_indices.append(idx)
		elif longest_side_m < SMALL_OBJECT_MAX_METERS:
			small_indices.append(idx)
		else:
			medium_indices.append(idx)
		idx += 1
	var ordered_indices: Array[int] = []
	ordered_indices.append_array(large_indices)
	ordered_indices.append_array(medium_indices)
	ordered_indices.append_array(small_indices)
	return ordered_indices


func _on_generate_pressed() -> void:
	if _editor_interface == null:
		_set_status("Autocliff: editor interface unavailable.", true)
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		_set_status("Autocliff: no edited scene.", true)
		return
	if _pool_resources.is_empty():
		_set_status("Autocliff: add one or more cliff meshes/scenes first.", true)
		return

	var target_path_text: String = _target_path_edit.text.strip_edges()
	if target_path_text.is_empty():
		_set_status("Autocliff: target path is empty.", true)
		return
	var target_any: Node = scene_root.get_node_or_null(NodePath(target_path_text))
	if target_any == null:
		_set_status("Autocliff: target path not found: %s" % target_path_text, true)
		return
	if not _is_valid_target_node(target_any):
		_set_status("Autocliff: target must be a Node3D surface root. Got: %s" % target_any.get_class(), true)
		return
	var target_node: Node3D = target_any as Node3D
	if target_node == null:
		_set_status("Autocliff: target is not Node3D-compatible.", true)
		return
	var output_name: String = _output_name_edit.text.strip_edges()
	if output_name.is_empty():
		output_name = "Autocliff_%s" % target_node.name
		_output_name_edit.text = output_name

	var world: World3D = target_node.get_world_3d()
	if world == null:
		_set_status("Autocliff: target has no World3D.", true)
		return
	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	if space_state == null:
		_set_status("Autocliff: no physics space available.", true)
		return

	var spacing: float = maxf(0.25, _sample_spacing_spin.value)
	var size_x: float = maxf(spacing, _area_size_x_spin.value)
	var size_z: float = maxf(spacing, _area_size_z_spin.value)
	var ray_height: float = maxf(1.0, _ray_height_spin.value)
	var slope_min: float = minf(_slope_min_spin.value, _slope_max_spin.value)
	var slope_max: float = maxf(_slope_min_spin.value, _slope_max_spin.value)
	var height_min: float = minf(_height_min_spin.value, _height_max_spin.value)
	var height_max: float = maxf(_height_min_spin.value, _height_max_spin.value)
	var density: float = clampf(_density_spin.value, 0.0, 1.0)
	var bury_min: float = minf(_bury_min_spin.value, _bury_max_spin.value)
	var bury_max: float = maxf(_bury_min_spin.value, _bury_max_spin.value)
	var scale_min: float = minf(_scale_min_spin.value, _scale_max_spin.value)
	var scale_max: float = maxf(_scale_min_spin.value, _scale_max_spin.value)
	var yaw_jitter_deg: float = maxf(0.0, _yaw_jitter_spin.value)
	var collision_mask: int = int(_collision_mask_spin.value)
	var clearance_radius_scale: float = maxf(0.01, _clearance_radius_scale_spin.value)
	var clearance_extra: float = maxf(0.0, _clearance_extra_spin.value)
	var use_clearance_check: bool = _avoid_collider_overlap_check.button_pressed
	var use_static_aabb_check: bool = _avoid_static_aabb_overlap_check.button_pressed
	var use_cluster_avoidance: bool = _avoid_cluster_overlap_check.button_pressed
	var target_is_terrain: bool = _is_terrain_node(target_node)
	var use_material_filter: bool = _material_filter_enabled_check.button_pressed and target_is_terrain
	var material_filter_id: int = int(_material_filter_id_spin.value)
	var material_filter_mode: int = _material_filter_mode_option.selected if _material_filter_mode_option != null else MATERIAL_FILTER_MODE_BASE_OR_OVERLAY
	if _material_filter_enabled_check.button_pressed and not target_is_terrain:
		_set_status("Autocliff: Terrain material filtering is only available for Terrain3D targets. Continuing without it.", false)
	var use_group_tuning: bool = _group_tuning_enabled_check.button_pressed
	var global_density_mult: float = maxf(0.0, _group_global_density_mult_spin.value)
	var global_scale_mult: float = maxf(0.01, _group_global_scale_mult_spin.value)
	var global_bury_mult: float = maxf(0.0, _group_global_bury_mult_spin.value)
	var global_yaw_mult: float = maxf(0.0, _group_global_yaw_mult_spin.value)
	var global_clearance_mult: float = maxf(0.01, _group_global_clearance_mult_spin.value)
	var global_cluster_mult: float = maxf(0.01, _group_global_cluster_mult_spin.value)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(_seed_spin.value)

	var x_count: int = int(floor(size_x / spacing)) + 1
	var z_count: int = int(floor(size_z / spacing)) + 1

	_ensure_pool_metadata()
	var buckets: Array = []
	var entry_clearance_radii: Array[float] = []
	var entry_group_ids: Array[int] = []
	var entry_count: int = _pool_resources.size()
	var generation_order_indices: Array[int] = _build_generation_order_indices(entry_count)
	var ordered_count: int = generation_order_indices.size()
	if ordered_count <= 0:
		var fallback_idx: int = 0
		while fallback_idx < entry_count:
			generation_order_indices.append(fallback_idx)
			fallback_idx += 1
		ordered_count = generation_order_indices.size()
	var mesh_idx: int = 0
	while mesh_idx < entry_count:
		buckets.append([])
		var base_radius: float = 0.5
		var longest_side_m: float = _get_pool_entry_effective_longest_side_meters(mesh_idx)
		entry_group_ids.append(_get_size_group_id(longest_side_m))
		if mesh_idx < _pool_bounds_radii.size():
			base_radius = maxf(0.01, _pool_bounds_radii[mesh_idx])
		else:
			base_radius = _estimate_pool_entry_clearance_radius(_pool_resources[mesh_idx], _pool_kinds[mesh_idx])
		entry_clearance_radii.append(base_radius)
		mesh_idx += 1

	var hit_count: int = 0
	var placed_count: int = 0
	var rejected_slope_count: int = 0
	var rejected_height_count: int = 0
	var rejected_density_count: int = 0
	var rejected_collision_count: int = 0
	var rejected_cluster_count: int = 0
	var rejected_material_count: int = 0
	var placed_large_count: int = 0
	var placed_medium_count: int = 0
	var placed_small_count: int = 0
	var placed_cluster_positions: Array[Vector3] = []
	var placed_cluster_radii: Array[float] = []
	var target_center: Vector3 = target_node.global_transform.origin
	var clearance_shape: SphereShape3D = SphereShape3D.new()
	var clearance_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	clearance_query.shape = clearance_shape
	clearance_query.collision_mask = ALL_COLLISION_LAYERS_MASK
	clearance_query.collide_with_bodies = true
	clearance_query.collide_with_areas = _clearance_check_areas_check.button_pressed
	clearance_query.margin = 0.0
	var existing_output_root: Node = scene_root.get_node_or_null(NodePath(output_name))
	var exclude_existing_output: Node = existing_output_root if _replace_existing_check.button_pressed else null
	var static_blocker_aabbs: Array[AABB] = []
	if use_static_aabb_check:
		static_blocker_aabbs = _collect_static_blocker_aabbs(scene_root, target_node, exclude_existing_output)

	var xi: int = 0
	while xi < x_count:
		var x_t: float = 0.0
		if x_count > 1:
			x_t = float(xi) / float(x_count - 1)
		var x_offset: float = lerpf(-size_x * 0.5, size_x * 0.5, x_t)

		var zi: int = 0
		while zi < z_count:
			var z_t: float = 0.0
			if z_count > 1:
				z_t = float(zi) / float(z_count - 1)
			var z_offset: float = lerpf(-size_z * 0.5, size_z * 0.5, z_t)

			var sample_origin: Vector3 = target_center + Vector3(x_offset, 0.0, z_offset)
			var from_pos: Vector3 = sample_origin + Vector3.UP * ray_height
			var to_pos: Vector3 = sample_origin + Vector3.DOWN * ray_height

			var hit: Dictionary = _sample_surface(space_state, target_node, sample_origin, from_pos, to_pos, collision_mask)
			if hit.is_empty():
				zi += 1
				continue
			hit_count += 1

			var normal: Vector3 = hit.get("normal", Vector3.UP)
			if normal.length_squared() < 0.000001:
				zi += 1
				continue
			normal = normal.normalized()
			var slope_dot: float = clampf(normal.dot(Vector3.UP), -1.0, 1.0)
			var slope_deg: float = rad_to_deg(acos(slope_dot))
			if slope_deg < slope_min or slope_deg > slope_max:
				rejected_slope_count += 1
				zi += 1
				continue
			var world_position: Vector3 = hit.get("position", sample_origin)
			if world_position.y < height_min or world_position.y > height_max:
				rejected_height_count += 1
				zi += 1
				continue
			if use_material_filter and target_is_terrain:
				if not _hit_matches_terrain_material_filter(hit, target_node, world_position, material_filter_id, material_filter_mode):
					rejected_material_count += 1
					zi += 1
					continue
			var terrain_material_density_factor: float = 1.0
			if target_is_terrain:
				terrain_material_density_factor = _get_terrain_material_density_factor(
					hit,
					target_node,
					world_position,
					material_filter_id,
					material_filter_mode,
					use_material_filter
				)
			if use_material_filter and terrain_material_density_factor <= 0.0:
				rejected_material_count += 1
				zi += 1
				continue

			var selected_mesh_index: int = 0
			if ordered_count > 1 and _slope_order_check.button_pressed:
				var t: float = 0.0
				if absf(slope_max - slope_min) > 0.0001:
					t = clampf((slope_deg - slope_min) / (slope_max - slope_min), 0.0, 0.999999)
				var ordered_idx: int = clampi(int(floor(t * float(ordered_count))), 0, ordered_count - 1)
				selected_mesh_index = generation_order_indices[ordered_idx]
			elif ordered_count > 1:
				var random_ordered_idx: int = rng.randi_range(0, ordered_count - 1)
				selected_mesh_index = generation_order_indices[random_ordered_idx]
			elif ordered_count == 1:
				selected_mesh_index = generation_order_indices[0]

			var group_id: int = entry_group_ids[selected_mesh_index] if selected_mesh_index < entry_group_ids.size() else SIZE_GROUP_MEDIUM
			var group_density_mult: float = 1.0
			var group_scale_mult: float = 1.0
			var group_bury_mult: float = 1.0
			var group_yaw_mult: float = 1.0
			var group_clearance_mult: float = 1.0
			var group_cluster_mult: float = 1.0
			var group_slope_min: float = slope_min
			var group_slope_max: float = slope_max
			if use_group_tuning:
				group_density_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_density_mult_spin,
					_group_medium_density_mult_spin,
					_group_small_density_mult_spin
				)
				group_scale_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_scale_mult_spin,
					_group_medium_scale_mult_spin,
					_group_small_scale_mult_spin
				)
				group_bury_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_bury_mult_spin,
					_group_medium_bury_mult_spin,
					_group_small_bury_mult_spin
				)
				group_yaw_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_yaw_mult_spin,
					_group_medium_yaw_mult_spin,
					_group_small_yaw_mult_spin
				)
				group_clearance_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_clearance_mult_spin,
					_group_medium_clearance_mult_spin,
					_group_small_clearance_mult_spin
				)
				group_cluster_mult = _get_group_spin_multiplier(
					group_id,
					_group_large_cluster_mult_spin,
					_group_medium_cluster_mult_spin,
					_group_small_cluster_mult_spin
				)
				if group_id == SIZE_GROUP_LARGE:
					group_slope_min = _group_large_slope_min_spin.value
					group_slope_max = _group_large_slope_max_spin.value
				elif group_id == SIZE_GROUP_SMALL:
					group_slope_min = _group_small_slope_min_spin.value
					group_slope_max = _group_small_slope_max_spin.value
				else:
					group_slope_min = _group_medium_slope_min_spin.value
					group_slope_max = _group_medium_slope_max_spin.value

			if group_slope_max < group_slope_min:
				var temp_group_slope: float = group_slope_min
				group_slope_min = group_slope_max
				group_slope_max = temp_group_slope
			group_slope_min = maxf(group_slope_min, slope_min)
			group_slope_max = minf(group_slope_max, slope_max)
			if slope_deg < group_slope_min or slope_deg > group_slope_max:
				rejected_slope_count += 1
				zi += 1
				continue

			var effective_density: float = clampf(density * global_density_mult * group_density_mult * terrain_material_density_factor, 0.0, 1.0)
			if rng.randf() > effective_density:
				rejected_density_count += 1
				zi += 1
				continue

			var effective_yaw_jitter_deg: float = maxf(0.0, yaw_jitter_deg * global_yaw_mult * group_yaw_mult)
			var basis: Basis = _build_cliff_basis(normal, effective_yaw_jitter_deg, rng)
			var effective_scale_min: float = maxf(0.01, scale_min * global_scale_mult * group_scale_mult)
			var effective_scale_max: float = maxf(0.01, scale_max * global_scale_mult * group_scale_mult)
			if effective_scale_max < effective_scale_min:
				var temp_scale: float = effective_scale_min
				effective_scale_min = effective_scale_max
				effective_scale_max = temp_scale
			var random_scale: float = rng.randf_range(effective_scale_min, effective_scale_max)
			basis = basis.scaled(Vector3(random_scale, random_scale, random_scale))

			var effective_bury_min: float = maxf(0.0, bury_min * global_bury_mult * group_bury_mult)
			var effective_bury_max: float = maxf(0.0, bury_max * global_bury_mult * group_bury_mult)
			if effective_bury_max < effective_bury_min:
				var temp_bury: float = effective_bury_min
				effective_bury_min = effective_bury_max
				effective_bury_max = temp_bury
			var bury_amount: float = rng.randf_range(effective_bury_min, effective_bury_max)
			var world_xf: Transform3D = Transform3D(basis, world_position - normal * bury_amount)

			var base_radius: float = entry_clearance_radii[selected_mesh_index]
			var effective_clearance_scale: float = maxf(0.01, clearance_radius_scale * global_clearance_mult * group_clearance_mult)
			var clearance_radius: float = maxf(0.01, base_radius * random_scale * effective_clearance_scale + clearance_extra)
			if use_clearance_check:
				if _placement_overlaps_blocker(space_state, clearance_query, clearance_shape, world_xf.origin, clearance_radius, target_node):
					rejected_collision_count += 1
					zi += 1
					continue
			if use_static_aabb_check:
				var bounds_size: Vector3 = _pool_bounds_sizes[selected_mesh_index] if selected_mesh_index < _pool_bounds_sizes.size() else Vector3.ONE
				if _placement_overlaps_static_aabbs(world_xf, bounds_size, clearance_radius, static_blocker_aabbs):
					rejected_collision_count += 1
					zi += 1
					continue
			if use_cluster_avoidance:
				var effective_cluster_mult: float = maxf(0.01, global_cluster_mult * group_cluster_mult)
				var cluster_radius: float = maxf(0.01, clearance_radius * effective_cluster_mult)
				if _placement_overlaps_generated_cluster(world_xf.origin, cluster_radius, placed_cluster_positions, placed_cluster_radii):
					rejected_cluster_count += 1
					zi += 1
					continue

			var bucket: Array = buckets[selected_mesh_index]
			bucket.append(world_xf)
			buckets[selected_mesh_index] = bucket
			if use_cluster_avoidance:
				var record_cluster_radius: float = maxf(0.01, clearance_radius * maxf(0.01, global_cluster_mult * group_cluster_mult))
				placed_cluster_positions.append(world_xf.origin)
				placed_cluster_radii.append(record_cluster_radius)
			placed_count += 1
			var placed_size_m: float = _get_pool_entry_effective_longest_side_meters(selected_mesh_index)
			if placed_size_m > LARGE_OBJECT_MIN_METERS:
				placed_large_count += 1
			elif placed_size_m < SMALL_OBJECT_MAX_METERS:
				placed_small_count += 1
			else:
				placed_medium_count += 1

			zi += 1
		xi += 1

	if placed_count == 0:
		_set_status(
			"Autocliff: no placements. Hits=%d, slope_reject=%d, height_reject=%d, material_reject=%d, density_reject=%d, collision_reject=%d, cluster_reject=%d. Try wider slope/height range, adjust material filter, larger area, lower clearance/cluster, or higher density."
			% [hit_count, rejected_slope_count, rejected_height_count, rejected_material_count, rejected_density_count, rejected_collision_count, rejected_cluster_count],
			true
		)
		return

	var output_parent: Node = target_node.get_parent()
	if output_parent == null:
		output_parent = scene_root

	if _replace_existing_check.button_pressed:
		var existing_output: Node = output_parent.get_node_or_null(NodePath(output_name))
		if existing_output != null:
			existing_output.queue_free()

	var output_root: Node3D = Node3D.new()
	output_root.name = output_name
	output_parent.add_child(output_root)
	output_root.owner = scene_root
	output_root.global_position = target_center
	output_root.add_to_group("densetsu_autocliff")

	var output_inverse: Transform3D = output_root.global_transform.affine_inverse()
	var used_output_names: Dictionary = {}

	var use_multimesh: bool = _use_multimesh_check.button_pressed
	_reset_filter_fix_caches()
	for ordered_mesh_idx: int in generation_order_indices:
		mesh_idx = ordered_mesh_idx
		var transforms: Array = buckets[mesh_idx]
		if transforms.is_empty():
			continue
		var entry_kind: String = _pool_kinds[mesh_idx]
		var entry_res: Resource = _pool_resources[mesh_idx]
		var mesh: Mesh = entry_res as Mesh
		var packed_scene: PackedScene = entry_res as PackedScene
		var output_mesh: Mesh = mesh
		var base_name: String = _get_pool_entry_base_name(mesh_idx, entry_res)
		if mesh != null:
			output_mesh = _get_filtered_mesh_for_output(mesh)
		if use_multimesh and entry_kind == "mesh" and output_mesh != null:
			var mm: MultiMesh = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = output_mesh
			mm.instance_count = transforms.size()
			var t_idx: int = 0
			while t_idx < transforms.size():
				var world_xf: Transform3D = transforms[t_idx]
				var local_xf: Transform3D = output_inverse * world_xf
				mm.set_instance_transform(t_idx, local_xf)
				t_idx += 1

			var mm_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
			mm_instance.name = _make_unique_name("%s_MM" % base_name, used_output_names)
			mm_instance.multimesh = mm
			output_root.add_child(mm_instance)
			mm_instance.owner = scene_root
		else:
			var t_idx_single: int = 0
			while t_idx_single < transforms.size():
				var single_world_xf: Transform3D = transforms[t_idx_single]
				var single_local_xf: Transform3D = output_inverse * single_world_xf
				if entry_kind == "scene" and packed_scene != null:
					var inst: Node = packed_scene.instantiate()
					var node3d_inst: Node3D = inst as Node3D
					if node3d_inst == null:
						t_idx_single += 1
						continue
					# Preserve authored root transform (import axis corrections, offsets, base rotation).
					var base_local_xf: Transform3D = node3d_inst.transform
					node3d_inst.transform = single_local_xf * base_local_xf
					_apply_filter_to_scene_instance_materials(node3d_inst)
					output_root.add_child(node3d_inst)
					node3d_inst.owner = scene_root
				else:
					var mesh_instance: MeshInstance3D = MeshInstance3D.new()
					mesh_instance.name = _make_unique_name(base_name, used_output_names)
					mesh_instance.mesh = output_mesh
					mesh_instance.transform = single_local_xf
					_apply_filter_to_mesh_instance_materials(mesh_instance)
					output_root.add_child(mesh_instance)
					mesh_instance.owner = scene_root
				t_idx_single += 1

	_set_status(
		"Autocliff complete: %d placed from %d ray hits (%d x %d samples). Groups order: Large (>15m) -> Medium (3m..15m) -> Small (<3m). Placed L/M/S=%d/%d/%d. Rejects slope=%d height=%d material=%d density=%d collision=%d cluster=%d."
		% [placed_count, hit_count, x_count, z_count, placed_large_count, placed_medium_count, placed_small_count, rejected_slope_count, rejected_height_count, rejected_material_count, rejected_density_count, rejected_collision_count, rejected_cluster_count],
		false
	)


func _build_cliff_basis(normal: Vector3, yaw_jitter_deg: float, rng: RandomNumberGenerator) -> Basis:
	# Align local Y (up) with surface normal to preserve authored mesh orientation.
	var up_axis: Vector3 = normal.normalized()
	var forward_axis: Vector3 = Vector3.DOWN - up_axis * Vector3.DOWN.dot(up_axis)
	if forward_axis.length_squared() < 0.000001:
		forward_axis = Vector3.FORWARD - up_axis * Vector3.FORWARD.dot(up_axis)
	if forward_axis.length_squared() < 0.000001:
		forward_axis = Vector3.RIGHT - up_axis * Vector3.RIGHT.dot(up_axis)
	if forward_axis.length_squared() < 0.000001:
		forward_axis = Vector3.FORWARD
	forward_axis = forward_axis.normalized()

	var x_axis: Vector3 = up_axis.cross(forward_axis)
	if x_axis.length_squared() < 0.000001:
		x_axis = Vector3.RIGHT
	x_axis = x_axis.normalized()
	var z_axis: Vector3 = x_axis.cross(up_axis).normalized()

	var basis: Basis = Basis(x_axis, up_axis, z_axis).orthonormalized()
	if yaw_jitter_deg > 0.0:
		var yaw_rad: float = deg_to_rad(rng.randf_range(-yaw_jitter_deg, yaw_jitter_deg))
		var yaw_basis: Basis = Basis(up_axis, yaw_rad)
		basis = (yaw_basis * basis).orthonormalized()
	return basis


func _sample_surface(
	space_state: PhysicsDirectSpaceState3D,
	target_node: Node3D,
	sample_origin: Vector3,
	from_pos: Vector3,
	to_pos: Vector3,
	collision_mask: int
) -> Dictionary:
	# Prefer Terrain3D data sampling for robust editor-time placement.
	if _is_terrain_node(target_node):
		var terrain_hit: Dictionary = _sample_terrain_data(target_node, sample_origin)
		if not terrain_hit.is_empty():
			return terrain_hit

	var safe_mask: int = collision_mask
	if safe_mask <= 0:
		safe_mask = ALL_COLLISION_LAYERS_MASK
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from_pos, to_pos, safe_mask)
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = true
	var hit: Dictionary = space_state.intersect_ray(ray_query)
	if hit.is_empty():
		return {}
	var collider_obj: Object = hit.get("collider", null)
	if not _hit_matches_target(collider_obj, target_node):
		return {}
	return hit


func _estimate_pool_entry_clearance_radius(resource: Resource, kind: String) -> float:
	var bounds_info: Dictionary = _compute_pool_entry_bounds(resource, kind)
	var radius_variant: Variant = bounds_info.get("radius", 0.5)
	var radius: float = float(radius_variant)
	return maxf(0.01, radius)


func _compute_pool_entry_bounds(resource: Resource, kind: String) -> Dictionary:
	if kind == "scene":
		return _estimate_scene_bounds(resource as PackedScene)
	return _estimate_mesh_bounds(resource as Mesh)


func _estimate_mesh_bounds(mesh: Mesh) -> Dictionary:
	if mesh == null:
		return {"size": Vector3.ONE, "radius": 0.5}
	var aabb: AABB = mesh.get_aabb()
	var size: Vector3 = aabb.size.abs()
	if size.length_squared() <= 0.000001:
		size = Vector3.ONE
	var extents: Vector3 = size * 0.5
	var radius: float = extents.length()
	if radius <= 0.001:
		radius = 0.5
	return {
		"size": size,
		"radius": radius
	}


func _estimate_mesh_clearance_radius(mesh: Mesh) -> float:
	var bounds_info: Dictionary = _estimate_mesh_bounds(mesh)
	var radius_variant: Variant = bounds_info.get("radius", 0.5)
	return maxf(0.01, float(radius_variant))


func _estimate_transformed_aabb_clearance_radius(xform: Transform3D, aabb: AABB) -> float:
	var extents: Vector3 = aabb.size * 0.5
	var local_center: Vector3 = aabb.position + extents
	var world_center: Vector3 = xform * local_center
	# Account for authored node scaling (and parent scaling) when estimating clearance.
	var b: Basis = xform.basis
	var axis_x_len: float = b.x.length()
	var axis_y_len: float = b.y.length()
	var axis_z_len: float = b.z.length()
	var scaled_radius: float = sqrt(
		pow(extents.x * axis_x_len, 2.0) +
		pow(extents.y * axis_y_len, 2.0) +
		pow(extents.z * axis_z_len, 2.0)
	)
	return world_center.length() + scaled_radius


func _estimate_world_aligned_aabb(xform: Transform3D, aabb: AABB) -> AABB:
	var local_half_size: Vector3 = aabb.size * 0.5
	var local_center: Vector3 = aabb.position + local_half_size
	var world_center: Vector3 = xform * local_center
	var basis: Basis = xform.basis
	var world_half_size: Vector3 = Vector3(
		absf(basis.x.x) * local_half_size.x + absf(basis.y.x) * local_half_size.y + absf(basis.z.x) * local_half_size.z,
		absf(basis.x.y) * local_half_size.x + absf(basis.y.y) * local_half_size.y + absf(basis.z.y) * local_half_size.z,
		absf(basis.x.z) * local_half_size.x + absf(basis.y.z) * local_half_size.y + absf(basis.z.z) * local_half_size.z
	)
	return AABB(world_center - world_half_size, world_half_size * 2.0)


func _estimate_scene_bounds(scene: PackedScene) -> Dictionary:
	if scene == null:
		return {"size": Vector3.ONE, "radius": 0.75}
	var inst: Node = scene.instantiate()
	var found_bounds: bool = false
	var merged_aabb: AABB = AABB()
	var max_radius: float = 0.0
	var stack: Array[Dictionary] = [{"node": inst, "xf": Transform3D.IDENTITY}]
	while not stack.is_empty():
		var item: Dictionary = stack.pop_back()
		var node_variant: Variant = item.get("node", null)
		var node: Node = node_variant as Node
		if node == null:
			continue
		var parent_xf_variant: Variant = item.get("xf", Transform3D.IDENTITY)
		var parent_xf: Transform3D = parent_xf_variant if parent_xf_variant is Transform3D else Transform3D.IDENTITY

		var node3d: Node3D = node as Node3D
		var node_xf: Transform3D = parent_xf
		if node3d != null:
			node_xf = parent_xf * node3d.transform
		for child_any: Variant in node.get_children():
			var child: Node = child_any as Node
			if child != null:
				stack.append({"node": child, "xf": node_xf})
		if node3d == null:
			continue
		var node_pos: Vector3 = node_xf.origin

		var mesh_instance: MeshInstance3D = node3d as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			var mesh_aabb: AABB = mesh_instance.mesh.get_aabb()
			var world_aabb: AABB = _estimate_world_aligned_aabb(node_xf, mesh_aabb)
			if found_bounds:
				merged_aabb = merged_aabb.merge(world_aabb)
			else:
				merged_aabb = world_aabb
				found_bounds = true
			var mesh_radius: float = _estimate_transformed_aabb_clearance_radius(node_xf, mesh_aabb)
			max_radius = maxf(max_radius, mesh_radius)

		var collision_shape: CollisionShape3D = node3d as CollisionShape3D
		if collision_shape != null and collision_shape.shape != null:
			var debug_mesh: Mesh = collision_shape.shape.get_debug_mesh()
			if debug_mesh != null:
				var collision_aabb: AABB = debug_mesh.get_aabb()
				var collision_world_aabb: AABB = _estimate_world_aligned_aabb(node_xf, collision_aabb)
				if found_bounds:
					merged_aabb = merged_aabb.merge(collision_world_aabb)
				else:
					merged_aabb = collision_world_aabb
					found_bounds = true
				var collision_radius: float = _estimate_transformed_aabb_clearance_radius(node_xf, collision_aabb)
				max_radius = maxf(max_radius, collision_radius)
			else:
				max_radius = maxf(max_radius, node_pos.length() + 0.5)

	if is_instance_valid(inst):
		inst.free()

	var size: Vector3 = Vector3.ONE
	if found_bounds:
		size = merged_aabb.size.abs()
		if size.length_squared() <= 0.000001:
			size = Vector3.ONE
	if max_radius <= 0.001:
		var half_size: Vector3 = size * 0.5
		max_radius = maxf(0.75, half_size.length())
	return {
		"size": size,
		"radius": max_radius
	}


func _reset_filter_fix_caches() -> void:
	_filtered_material_cache.clear()
	_filtered_mesh_cache.clear()


func _get_filtered_mesh_for_output(mesh: Mesh) -> Mesh:
	if mesh == null:
		return null
	var key: String = _mesh_group_key(mesh)
	var cached_any: Variant = _filtered_mesh_cache.get(key, null)
	if cached_any is Mesh:
		return cached_any as Mesh
	var out_mesh: Mesh = mesh.duplicate(true) as Mesh
	if out_mesh == null:
		out_mesh = mesh
	var surface_count: int = out_mesh.get_surface_count()
	var i: int = 0
	while i < surface_count:
		var mat: Material = out_mesh.surface_get_material(i)
		var fixed: Material = _get_filtered_material_for_output(mat)
		if fixed != null and fixed != mat:
			out_mesh.surface_set_material(i, fixed)
		i += 1
	_filtered_mesh_cache[key] = out_mesh
	return out_mesh


func _apply_filter_to_scene_instance_materials(root_node: Node3D) -> void:
	if root_node == null:
		return
	var mesh_nodes: Array[Node] = root_node.find_children("", "MeshInstance3D", true, false)
	for mesh_node_any: Variant in mesh_nodes:
		var mesh_node: MeshInstance3D = mesh_node_any as MeshInstance3D
		if mesh_node == null:
			continue
		_apply_filter_to_mesh_instance_materials(mesh_node)


func _apply_filter_to_mesh_instance_materials(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance == null:
		return
	var override_mat: Material = mesh_instance.material_override
	var override_fixed: Material = _get_filtered_material_for_output(override_mat)
	if override_fixed != null and override_fixed != override_mat:
		mesh_instance.material_override = override_fixed
	if mesh_instance.mesh == null:
		return
	var surface_count: int = mesh_instance.mesh.get_surface_count()
	var i: int = 0
	while i < surface_count:
		var surface_override: Material = mesh_instance.get_surface_override_material(i)
		var target_source: Material = surface_override
		if target_source == null:
			target_source = mesh_instance.get_active_material(i)
		var target_fixed: Material = _get_filtered_material_for_output(target_source)
		if target_fixed != null and target_fixed != surface_override:
			mesh_instance.set_surface_override_material(i, target_fixed)
		i += 1


func _get_filtered_material_for_output(material: Material) -> Material:
	if material == null:
		return null
	var key: String = str(material.get_instance_id())
	if _filtered_material_cache.has(key):
		return _filtered_material_cache.get(key, material) as Material
	var out: Material = material
	var base_material: BaseMaterial3D = material as BaseMaterial3D
	if base_material != null:
		if int(base_material.texture_filter) != BASE_MATERIAL_FILTER_LINEAR_MIPMAP_ANISO:
			var dup_base: BaseMaterial3D = base_material.duplicate(true) as BaseMaterial3D
			if dup_base != null:
				dup_base.resource_local_to_scene = true
				dup_base.texture_filter = BASE_MATERIAL_FILTER_LINEAR_MIPMAP_ANISO
				out = dup_base
	_filtered_material_cache[key] = out
	return out


func _estimate_scene_clearance_radius(scene: PackedScene) -> float:
	var bounds_info: Dictionary = _estimate_scene_bounds(scene)
	var radius_variant: Variant = bounds_info.get("radius", 0.75)
	return maxf(0.01, float(radius_variant))


func _placement_overlaps_blocker(
	space_state: PhysicsDirectSpaceState3D,
	query: PhysicsShapeQueryParameters3D,
	sphere: SphereShape3D,
	world_position: Vector3,
	radius: float,
	target_node: Node3D
) -> bool:
	sphere.radius = maxf(0.01, radius)
	query.transform = Transform3D(Basis.IDENTITY, world_position)
	var hits: Array = space_state.intersect_shape(query, 16)
	if hits.is_empty():
		return false
	for hit_variant: Variant in hits:
		if not (hit_variant is Dictionary):
			continue
		var hit: Dictionary = hit_variant as Dictionary
		var collider_obj: Object = hit.get("collider", null)
		if collider_obj == null:
			continue
		if _hit_matches_target(collider_obj, target_node):
			continue
		return true
	return false


func _placement_overlaps_static_aabbs(
	world_xf: Transform3D,
	bounds_size: Vector3,
	clearance_radius: float,
	blocker_aabbs: Array[AABB]
) -> bool:
	if blocker_aabbs.is_empty():
		return false
	var safe_size: Vector3 = bounds_size.abs()
	var min_side: float = maxf(0.01, clearance_radius * 2.0)
	safe_size.x = maxf(safe_size.x, min_side)
	safe_size.y = maxf(safe_size.y, min_side)
	safe_size.z = maxf(safe_size.z, min_side)
	var local_aabb: AABB = AABB(-safe_size * 0.5, safe_size)
	var candidate_aabb: AABB = _estimate_world_aligned_aabb(world_xf, local_aabb)
	for blocker_aabb: AABB in blocker_aabbs:
		if candidate_aabb.intersects(blocker_aabb):
			return true
	return false


func _collect_static_blocker_aabbs(scene_root: Node, target_node: Node3D, exclude_root: Node) -> Array[AABB]:
	var out: Array[AABB] = []
	if scene_root == null:
		return out
	var stack: Array[Node] = [scene_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child_any: Variant in node.get_children():
			var child: Node = child_any as Node
			if child != null:
				stack.append(child)

		if node == target_node:
			continue
		if exclude_root != null and (node == exclude_root or _is_node_under(node, exclude_root)):
			continue
		if _is_node_under(node, target_node):
			continue
		if _is_node_under_dynamic_body(node):
			continue

		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			var mesh_aabb: AABB = mesh_instance.mesh.get_aabb()
			out.append(_estimate_world_aligned_aabb(mesh_instance.global_transform, mesh_aabb))
			continue

		var mm_instance: MultiMeshInstance3D = node as MultiMeshInstance3D
		if mm_instance != null and mm_instance.multimesh != null and mm_instance.multimesh.mesh != null:
			var mm: MultiMesh = mm_instance.multimesh
			var mm_mesh_aabb: AABB = mm.mesh.get_aabb()
			var i: int = 0
			while i < mm.instance_count:
				var world_xf: Transform3D = mm_instance.global_transform * mm.get_instance_transform(i)
				out.append(_estimate_world_aligned_aabb(world_xf, mm_mesh_aabb))
				i += 1
			continue
	return out


func _is_node_under(node: Node, possible_ancestor: Node) -> bool:
	if node == null or possible_ancestor == null:
		return false
	var current: Node = node
	while current != null:
		if current == possible_ancestor:
			return true
		current = current.get_parent()
	return false


func _is_node_under_dynamic_body(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is CharacterBody3D or current is RigidBody3D or current is AnimatableBody3D:
			return true
		if current is StaticBody3D:
			return false
		current = current.get_parent()
	return false


func _sample_terrain_data(target_node: Node3D, sample_origin: Vector3) -> Dictionary:
	var terrain_data: Object = target_node.get("data") as Object
	if terrain_data == null:
		return {}
	if not terrain_data.has_method("get_height"):
		return {}
	var height_variant: Variant = terrain_data.call("get_height", sample_origin)
	var height_value: float = NAN
	var height_type: int = typeof(height_variant)
	if height_type == TYPE_FLOAT or height_type == TYPE_INT:
		height_value = float(height_variant)
	if is_nan(height_value):
		return {}

	var normal_value: Vector3 = Vector3.UP
	if terrain_data.has_method("get_normal"):
		var normal_variant: Variant = terrain_data.call("get_normal", sample_origin)
		if typeof(normal_variant) == TYPE_VECTOR3:
			normal_value = normal_variant
	if normal_value.length_squared() <= 0.000001:
		normal_value = Vector3.UP
	else:
		normal_value = normal_value.normalized()
	var sample_position: Vector3 = Vector3(sample_origin.x, height_value, sample_origin.z)
	var base_id: int = -1
	var overlay_id: int = -1
	var dominant_id: int = -1
	var blend_value: float = -1.0
	if terrain_data.has_method("get_control_base_id"):
		base_id = _variant_to_int_or_default(terrain_data.call("get_control_base_id", sample_position), -1)
	if terrain_data.has_method("get_control_overlay_id"):
		overlay_id = _variant_to_int_or_default(terrain_data.call("get_control_overlay_id", sample_position), -1)
	if terrain_data.has_method("get_texture_id"):
		var parsed_texture: Dictionary = _parse_terrain_texture_id_variant(terrain_data.call("get_texture_id", sample_position))
		var parsed_base: int = _variant_to_int_or_default(parsed_texture.get("base", -1), -1)
		var parsed_overlay: int = _variant_to_int_or_default(parsed_texture.get("overlay", -1), -1)
		var parsed_dominant: int = _variant_to_int_or_default(parsed_texture.get("dominant", -1), -1)
		var parsed_blend: float = _variant_to_float_or_default(parsed_texture.get("blend", -1.0), -1.0)
		if base_id < 0 and parsed_base >= 0:
			base_id = parsed_base
		if overlay_id < 0 and parsed_overlay >= 0:
			overlay_id = parsed_overlay
		dominant_id = parsed_dominant
		blend_value = parsed_blend
	if dominant_id < 0:
		if blend_value >= 0.0 and base_id >= 0 and overlay_id >= 0:
			dominant_id = overlay_id if blend_value >= 0.5 else base_id
		elif base_id >= 0:
			dominant_id = base_id
		elif overlay_id >= 0:
			dominant_id = overlay_id

	return {
		"position": sample_position,
		"normal": normal_value,
		"collider": target_node,
		"terrain_base_id": base_id,
		"terrain_overlay_id": overlay_id,
		"terrain_texture_id": dominant_id,
		"terrain_blend": blend_value
	}


func _hit_matches_terrain_material_filter(
	hit: Dictionary,
	target_node: Node3D,
	world_position: Vector3,
	material_id: int,
	filter_mode: int
) -> bool:
	var ids: Dictionary = _get_terrain_material_ids_for_point(hit, target_node, world_position, filter_mode)
	var base_id: int = _variant_to_int_or_default(ids.get("base", -1), -1)
	var overlay_id: int = _variant_to_int_or_default(ids.get("overlay", -1), -1)
	var dominant_id: int = _variant_to_int_or_default(ids.get("dominant", -1), -1)
	match filter_mode:
		MATERIAL_FILTER_MODE_BASE_ONLY:
			return base_id == material_id
		MATERIAL_FILTER_MODE_OVERLAY_ONLY:
			return overlay_id == material_id
		MATERIAL_FILTER_MODE_DOMINANT:
			return dominant_id == material_id
		_:
			return base_id == material_id or overlay_id == material_id


func _get_terrain_material_ids_for_point(hit: Dictionary, target_node: Node3D, world_position: Vector3, filter_mode: int) -> Dictionary:
	var base_id: int = _variant_to_int_or_default(hit.get("terrain_base_id", -1), -1)
	var overlay_id: int = _variant_to_int_or_default(hit.get("terrain_overlay_id", -1), -1)
	var dominant_id: int = _variant_to_int_or_default(hit.get("terrain_texture_id", -1), -1)
	var blend_value: float = _variant_to_float_or_default(hit.get("terrain_blend", -1.0), -1.0)
	var dominant_required: bool = filter_mode == MATERIAL_FILTER_MODE_DOMINANT
	if base_id >= 0 and overlay_id >= 0 and (not dominant_required or dominant_id >= 0):
		return {"base": base_id, "overlay": overlay_id, "dominant": dominant_id, "blend": blend_value}

	var terrain_data: Object = target_node.get("data") as Object
	if terrain_data == null:
		return {"base": base_id, "overlay": overlay_id, "dominant": dominant_id, "blend": blend_value}
	if base_id < 0 and terrain_data.has_method("get_control_base_id"):
		base_id = _variant_to_int_or_default(terrain_data.call("get_control_base_id", world_position), -1)
	if overlay_id < 0 and terrain_data.has_method("get_control_overlay_id"):
		overlay_id = _variant_to_int_or_default(terrain_data.call("get_control_overlay_id", world_position), -1)
	if (dominant_required or dominant_id < 0 or blend_value < 0.0) and terrain_data.has_method("get_texture_id"):
		var parsed_texture: Dictionary = _parse_terrain_texture_id_variant(terrain_data.call("get_texture_id", world_position))
		var parsed_base: int = _variant_to_int_or_default(parsed_texture.get("base", -1), -1)
		var parsed_overlay: int = _variant_to_int_or_default(parsed_texture.get("overlay", -1), -1)
		var parsed_dominant: int = _variant_to_int_or_default(parsed_texture.get("dominant", -1), -1)
		var parsed_blend: float = _variant_to_float_or_default(parsed_texture.get("blend", -1.0), -1.0)
		if base_id < 0 and parsed_base >= 0:
			base_id = parsed_base
		if overlay_id < 0 and parsed_overlay >= 0:
			overlay_id = parsed_overlay
		if dominant_id < 0 and parsed_dominant >= 0:
			dominant_id = parsed_dominant
		if blend_value < 0.0 and parsed_blend >= 0.0:
			blend_value = parsed_blend
	if dominant_id < 0:
		if blend_value >= 0.0 and base_id >= 0 and overlay_id >= 0:
			dominant_id = overlay_id if blend_value >= 0.5 else base_id
		elif base_id >= 0:
			dominant_id = base_id
		elif overlay_id >= 0:
			dominant_id = overlay_id
	return {"base": base_id, "overlay": overlay_id, "dominant": dominant_id, "blend": blend_value}


func _get_terrain_material_density_factor(
	hit: Dictionary,
	target_node: Node3D,
	world_position: Vector3,
	material_id: int,
	filter_mode: int,
	use_material_filter: bool
) -> float:
	if not use_material_filter:
		return 1.0
	var ids: Dictionary = _get_terrain_material_ids_for_point(hit, target_node, world_position, filter_mode)
	var base_id: int = _variant_to_int_or_default(ids.get("base", -1), -1)
	var overlay_id: int = _variant_to_int_or_default(ids.get("overlay", -1), -1)
	var dominant_id: int = _variant_to_int_or_default(ids.get("dominant", -1), -1)
	var blend_value: float = _variant_to_float_or_default(ids.get("blend", -1.0), -1.0)
	var base_weight: float = 1.0
	var overlay_weight: float = 1.0
	if blend_value >= 0.0:
		base_weight = clampf(1.0 - blend_value, 0.0, 1.0)
		overlay_weight = clampf(blend_value, 0.0, 1.0)
	elif dominant_id >= 0:
		base_weight = 1.0 if dominant_id == base_id else 0.0
		overlay_weight = 1.0 if dominant_id == overlay_id else 0.0

	match filter_mode:
		MATERIAL_FILTER_MODE_BASE_ONLY:
			return base_weight if base_id == material_id else 0.0
		MATERIAL_FILTER_MODE_OVERLAY_ONLY:
			return overlay_weight if overlay_id == material_id else 0.0
		MATERIAL_FILTER_MODE_DOMINANT:
			if dominant_id < 0:
				if base_id == material_id:
					return base_weight
				if overlay_id == material_id:
					return overlay_weight
				return 0.0
			return 1.0 if dominant_id == material_id else 0.0
		_:
			var density_factor: float = 0.0
			if base_id == material_id:
				density_factor = maxf(density_factor, base_weight)
			if overlay_id == material_id:
				density_factor = maxf(density_factor, overlay_weight)
			return density_factor


func _variant_to_int_or_default(value: Variant, default_value: int) -> int:
	var t: int = typeof(value)
	if t == TYPE_INT:
		return value
	if t == TYPE_FLOAT:
		return int(value)
	if t == TYPE_BOOL:
		return 1 if bool(value) else 0
	if t == TYPE_STRING:
		var s: String = String(value).strip_edges()
		if s.is_valid_int():
			return int(s)
	return default_value


func _variant_to_float_or_default(value: Variant, default_value: float) -> float:
	var t: int = typeof(value)
	if t == TYPE_FLOAT or t == TYPE_INT:
		return float(value)
	if t == TYPE_STRING:
		var s: String = String(value).strip_edges()
		if s.is_valid_float():
			return float(s)
	return default_value


func _parse_terrain_texture_id_variant(value: Variant) -> Dictionary:
	var parsed: Dictionary = {
		"base": -1,
		"overlay": -1,
		"dominant": -1,
		"blend": -1.0
	}
	var t: int = typeof(value)
	if t == TYPE_VECTOR3:
		var vec3_value: Vector3 = value
		var base_id: int = int(round(vec3_value.x))
		var overlay_id: int = int(round(vec3_value.y))
		var blend_value: float = clampf(vec3_value.z, 0.0, 1.0)
		parsed["base"] = base_id
		parsed["overlay"] = overlay_id
		parsed["blend"] = blend_value
		parsed["dominant"] = overlay_id if blend_value >= 0.5 else base_id
		return parsed
	if t == TYPE_VECTOR2:
		var vec2_value: Vector2 = value
		var base_id_v2: int = int(round(vec2_value.x))
		var overlay_id_v2: int = int(round(vec2_value.y))
		parsed["base"] = base_id_v2
		parsed["overlay"] = overlay_id_v2
		parsed["dominant"] = base_id_v2
		return parsed
	if t == TYPE_DICTIONARY:
		var dict_value: Dictionary = value
		parsed["base"] = _variant_to_int_or_default(dict_value.get("base", dict_value.get("base_id", -1)), -1)
		parsed["overlay"] = _variant_to_int_or_default(dict_value.get("overlay", dict_value.get("overlay_id", -1)), -1)
		parsed["dominant"] = _variant_to_int_or_default(dict_value.get("dominant", dict_value.get("texture_id", -1)), -1)
		parsed["blend"] = _variant_to_float_or_default(dict_value.get("blend", -1.0), -1.0)
		return parsed
	if t == TYPE_ARRAY:
		var arr_value: Array = value
		if arr_value.size() >= 1:
			parsed["base"] = _variant_to_int_or_default(arr_value[0], -1)
		if arr_value.size() >= 2:
			parsed["overlay"] = _variant_to_int_or_default(arr_value[1], -1)
		if arr_value.size() >= 3:
			parsed["blend"] = _variant_to_float_or_default(arr_value[2], -1.0)
		if arr_value.size() >= 4:
			parsed["dominant"] = _variant_to_int_or_default(arr_value[3], -1)
		return parsed
	var dominant_id: int = _variant_to_int_or_default(value, -1)
	parsed["dominant"] = dominant_id
	return parsed


func _hit_matches_target(collider_obj: Object, target: Node3D) -> bool:
	if _is_collider_under_target(collider_obj, target):
		return true
	if _is_terrain_node(target):
		# Terrain3D can use internal collision wrappers not parented under the target node.
		return true
	return false


func _is_collider_under_target(collider_obj: Object, target: Node3D) -> bool:
	var node: Node = collider_obj as Node
	if node == null:
		return false
	var current: Node = node
	while current != null:
		if current == target:
			return true
		current = current.get_parent()
	return false


func _on_clear_generated_pressed() -> void:
	if _editor_interface == null:
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		return
	var target_path_text: String = _target_path_edit.text.strip_edges()
	if target_path_text.is_empty():
		_set_status("Autocliff: target path is empty.", true)
		return
	var target_any: Node = scene_root.get_node_or_null(NodePath(target_path_text))
	if target_any == null:
		_set_status("Autocliff: target path not found.", true)
		return
	if not _is_valid_target_node(target_any):
		_set_status("Autocliff: target must be a Node3D surface root.", true)
		return
	var target_node: Node3D = target_any as Node3D
	if target_node == null:
		_set_status("Autocliff: target is not Node3D-compatible.", true)
		return
	var output_parent: Node = target_node.get_parent()
	if output_parent == null:
		output_parent = scene_root
	var output_name: String = _output_name_edit.text.strip_edges()
	if output_name.is_empty():
		output_name = "Autocliff_%s" % target_node.name
	var existing_output: Node = output_parent.get_node_or_null(NodePath(output_name))
	if existing_output == null:
		_set_status("Autocliff: no generated node found to clear.", true)
		return
	existing_output.queue_free()
	_set_status("Autocliff: cleared generated node '%s'." % output_name, false)


func _get_filesystem_selection_paths() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if _editor_interface == null:
		return out

	if _editor_interface.has_method("get_selected_paths"):
		var iface_selection: Variant = _editor_interface.call("get_selected_paths")
		if iface_selection is PackedStringArray:
			out = iface_selection
		elif iface_selection is Array:
			for item in (iface_selection as Array):
				out.append(str(item))
	if out.size() > 0:
		return out

	var dock: Object = _editor_interface.get_file_system_dock()
	if dock == null:
		return out

	if dock.has_method("get_selected_paths"):
		var selected_paths_any: Variant = dock.call("get_selected_paths")
		if selected_paths_any is PackedStringArray:
			return selected_paths_any
		if selected_paths_any is Array:
			for item in (selected_paths_any as Array):
				out.append(str(item))
			if out.size() > 0:
				return out

	if dock.has_method("get_selected_files"):
		var selected_files_any: Variant = dock.call("get_selected_files")
		if selected_files_any is PackedStringArray:
			return selected_files_any
		if selected_files_any is Array:
			for item in (selected_files_any as Array):
				out.append(str(item))
			if out.size() > 0:
				return out

	if dock.has_method("get_selected_file"):
		var selected_file_any: Variant = dock.call("get_selected_file")
		if selected_file_any is String and str(selected_file_any) != "":
			out.append(str(selected_file_any))
	return out


func _normalize_to_res_path(raw_path: String) -> String:
	var path: String = raw_path.strip_edges()
	if path.is_empty():
		return ""
	if not path.begins_with("res://"):
		path = ProjectSettings.localize_path(path)
	return path


func _is_supported_pool_path(path: String) -> bool:
	var lower_path: String = path.to_lower()
	for ext in _supported_pool_extensions:
		if lower_path.ends_with(ext):
			return true
	return false


func _get_first_selected_node3d() -> Node3D:
	if _editor_interface == null:
		return null
	var selection: EditorSelection = _editor_interface.get_selection()
	if selection == null:
		return null
	var selected_nodes: Array = selection.get_selected_nodes()
	for item in selected_nodes:
		var node3d: Node3D = item as Node3D
		if node3d != null:
			return node3d
	return null


func _get_first_selected_target_node() -> Node3D:
	if _editor_interface == null:
		return null
	var selection: EditorSelection = _editor_interface.get_selection()
	if selection == null:
		return null
	var selected_nodes: Array = selection.get_selected_nodes()
	var fallback_node: Node3D = null
	for item in selected_nodes:
		var node: Node = item as Node
		if node == null:
			continue
		if _is_terrain_node(node):
			return node as Node3D
		if fallback_node == null and node is Node3D:
			fallback_node = node as Node3D
	return fallback_node


func _is_valid_target_node(node: Node) -> bool:
	return node is Node3D


func _is_terrain_node(node: Node) -> bool:
	if node == null:
		return false
	return node.is_class("Terrain3D")


func _set_status(message: String, is_error: bool) -> void:
	if _status_label == null:
		return
	if is_error:
		_status_label.text = "ERROR: " + message
	else:
		_status_label.text = message
