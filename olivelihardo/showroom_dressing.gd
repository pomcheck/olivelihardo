extends Node3D

const TOON_SHADER: Shader = preload("res://shaders/toon_cel.gdshader")
const WOOD_TEXTURE: Texture2D = preload("res://textures/oak_grain.svg")
const FABRIC_TEXTURE: Texture2D = preload("res://textures/upholstery_weave.svg")
const RUG_TEXTURE: Texture2D = preload("res://textures/rug_medallion.svg")
const SCUFF_TEXTURE: Texture2D = preload("res://textures/floor_scuffs.svg")
const ARROW_TEXTURE: Texture2D = preload("res://textures/direction_arrow.svg")
const WELCOME_TEXTURE: Texture2D = preload("res://textures/store_welcome.svg")
const SALE_TEXTURE: Texture2D = preload("res://textures/store_sale.svg")
const DEPARTMENT_TEXTURE: Texture2D = preload("res://textures/department_sign.svg")
const PRICE_TEXTURE: Texture2D = preload("res://textures/price_tag.svg")

const LANE_X: Array[float] = [-24.0, -12.0, 0.0, 12.0, 24.0]
const FLOOR_HEIGHTS: Array[float] = [0.0, 2.5, 1.5, 4.0, 5.0]
const FABRIC_COLORS: Array[Color] = [
	Color(0.75, 0.32, 0.23),
	Color(0.25, 0.49, 0.66),
	Color(0.74, 0.61, 0.32),
	Color(0.37, 0.55, 0.40),
	Color(0.61, 0.39, 0.59)
]

var _random := RandomNumberGenerator.new()
var _wood_material: ShaderMaterial
var _fabric_materials: Array[ShaderMaterial] = []
var _rug_material: ShaderMaterial
var _scuff_material: StandardMaterial3D
var _arrow_material: StandardMaterial3D
var _welcome_material: StandardMaterial3D
var _sale_material: StandardMaterial3D
var _department_material: StandardMaterial3D
var _price_material: StandardMaterial3D
var _rail_material: ShaderMaterial


func _ready() -> void:
	_random.seed = 61824
	_create_materials()
	_create_start_gate()
	_create_ramp_rails()
	_create_wayfinding()
	_create_floor_wear_and_rugs()
	_create_department_vignettes()
	_add_sofa_details()
	_create_promo_boards()


func _create_materials() -> void:
	_wood_material = _toon_material(Color(0.86, 0.62, 0.39), WOOD_TEXTURE, Vector2(2, 2))
	_rug_material = _toon_material(Color(1.0, 0.94, 0.84), RUG_TEXTURE, Vector2.ONE)
	_rail_material = _toon_material(Color(0.93, 0.68, 0.24), null, Vector2.ONE)
	for fabric_color: Color in FABRIC_COLORS:
		_fabric_materials.append(
			_toon_material(fabric_color, FABRIC_TEXTURE, Vector2(2.5, 2.5))
		)

	_scuff_material = _image_material(SCUFF_TEXTURE, Color(1.0, 1.0, 1.0, 0.8), true)
	_arrow_material = _image_material(ARROW_TEXTURE, Color.WHITE)
	_welcome_material = _image_material(WELCOME_TEXTURE, Color.WHITE)
	_sale_material = _image_material(SALE_TEXTURE, Color.WHITE)
	_department_material = _image_material(DEPARTMENT_TEXTURE, Color.WHITE)
	_price_material = _image_material(PRICE_TEXTURE, Color.WHITE)


func _create_start_gate() -> void:
	var gate_x: float = -29.25
	_add_box_visual(self, Vector3(gate_x, 1.55, 26.8), Vector3(0.34, 3.1, 0.34), _wood_material)
	_add_box_visual(self, Vector3(gate_x, 1.55, 31.2), Vector3(0.34, 3.1, 0.34), _wood_material)
	_add_box_visual(self, Vector3(gate_x, 3.12, 29.0), Vector3(0.38, 0.4, 4.8), _wood_material)
	_add_box_collision(Vector3(gate_x, 0.0, 26.8), Vector3(0.34, 3.1, 0.34))
	_add_box_collision(Vector3(gate_x, 0.0, 31.2), Vector3(0.34, 3.1, 0.34))
	_add_box_collision(Vector3(gate_x, 2.92, 29.0), Vector3(0.38, 0.4, 4.8))
	_add_billboard(
		Vector3(gate_x - 0.04, 4.25, 29.0),
		PI * 0.5,
		Vector2(4.5, 1.8),
		_welcome_material
	)
	_add_billboard(
		Vector3(-28.5, 1.15, 23.45),
		PI * 0.5,
		Vector2(2.2, 1.3),
		_sale_material,
		0.0
	)


func _create_ramp_rails() -> void:
	var ramp_centers: Array[Vector3] = [
		Vector3(-18.0, 1.25, 29.0),
		Vector3(-6.0, 2.0, -29.0),
		Vector3(6.0, 2.75, 29.0),
		Vector3(18.0, 4.5, -29.0)
	]
	var x_rotations: Array[float] = [-0.17671, 0.07034, -0.17671, -0.07034]

	for ramp_index: int in range(ramp_centers.size()):
		var grip_strip_group := Node3D.new()
		grip_strip_group.name = "RampGripStrips%d" % (ramp_index + 1)
		grip_strip_group.position = ramp_centers[ramp_index] + Vector3(0.0, -0.06, 0.0)
		grip_strip_group.rotation = Vector3(x_rotations[ramp_index], PI * 0.5, 0.0)
		add_child(grip_strip_group)

		for strip_index: int in range(7):
			var strip_mesh := BoxMesh.new()
			strip_mesh.size = Vector3(8.7, 0.025, 0.12)
			var strip := MeshInstance3D.new()
			strip.name = "AntiSlipStrip%d" % (strip_index + 1)
			strip.mesh = strip_mesh
			strip.material_override = _rail_material
			strip.position = Vector3(0.0, 0.074, -5.25 + float(strip_index) * 1.75)
			grip_strip_group.add_child(strip)

		for side: float in [-1.0, 1.0]:
			var rail := StaticBody3D.new()
			rail.name = "RampEdgeRail%d_%s" % [ramp_index + 1, "Left" if side < 0.0 else "Right"]
			rail.position = ramp_centers[ramp_index] + Vector3(0.0, 0.512, side * 4.55)
			rail.rotation = Vector3(x_rotations[ramp_index], PI * 0.5, 0.0)
			add_child(rail)

			var rail_size := Vector3(0.18, 1.04, 14.0)
			var collision := CollisionShape3D.new()
			var box_shape := BoxShape3D.new()
			box_shape.size = rail_size
			collision.shape = box_shape
			rail.add_child(collision)

			var mesh := BoxMesh.new()
			mesh.size = rail_size
			var rail_mesh := MeshInstance3D.new()
			rail_mesh.mesh = mesh
			rail_mesh.material_override = _rail_material
			rail.add_child(rail_mesh)


func _create_wayfinding() -> void:
	var arrow_sites: Array[Vector3] = [
		Vector3(-27.0, 0.03, 29.0),
		Vector3(-25.65, 0.03, 29.0),
		Vector3(-12.0, 2.53, 18.0),
		Vector3(-12.0, 2.53, 5.0),
		Vector3(-12.0, 2.53, -8.0),
		Vector3(-12.0, 2.53, -21.0),
		Vector3(0.0, 1.53, -17.0),
		Vector3(0.0, 1.53, -4.0),
		Vector3(0.0, 1.53, 9.0),
		Vector3(0.0, 1.53, 22.0),
		Vector3(12.0, 4.03, 17.0),
		Vector3(12.0, 4.03, 3.0),
		Vector3(12.0, 4.03, -11.0),
		Vector3(12.0, 4.03, -23.0),
		Vector3(24.0, 5.03, -19.0),
		Vector3(24.0, 5.03, -5.0),
		Vector3(24.0, 5.03, 9.0),
		Vector3(24.0, 5.03, 23.0)
	]
	var arrow_rotations: Array[float] = [
		0.0, 0.0,
		PI * 0.5, PI * 0.5, PI * 0.5, PI * 0.5,
		-PI * 0.5, -PI * 0.5, -PI * 0.5, -PI * 0.5,
		PI * 0.5, PI * 0.5, PI * 0.5, PI * 0.5,
		-PI * 0.5, -PI * 0.5, -PI * 0.5, -PI * 0.5
	]

	for index: int in range(arrow_sites.size()):
		var arrow := MeshInstance3D.new()
		arrow.name = "FloorArrow%02d" % (index + 1)
		var arrow_mesh := PlaneMesh.new()
		arrow_mesh.size = Vector2(1.55, 0.78)
		arrow.mesh = arrow_mesh
		arrow.material_override = _arrow_material
		arrow.position = arrow_sites[index]
		arrow.rotation.y = arrow_rotations[index]
		add_child(arrow)

	_add_billboard(Vector3(-8.0, 4.5, 24.0), 0.0, Vector2(2.8, 1.3), _department_material, 2.5)
	_add_billboard(Vector3(-15.5, 4.5, -24.0), 0.0, Vector2(2.8, 1.3), _sale_material, 2.5)
	_add_billboard(Vector3(-4.0, 3.5, 24.0), PI, Vector2(2.8, 1.3), _sale_material, 1.5)
	_add_billboard(Vector3(8.0, 6.0, -24.0), 0.0, Vector2(2.8, 1.3), _department_material, 4.0)


func _create_floor_wear_and_rugs() -> void:
	for lane_index: int in range(LANE_X.size()):
		var lane_x: float = LANE_X[lane_index]
		var floor_y: float = FLOOR_HEIGHTS[lane_index]

		for stain_index: int in range(9):
			var x_offset: float = _random.randf_range(-4.7, 4.7)
			var z_position: float = _random.randf_range(-20.0, 20.0)
			var scuff := MeshInstance3D.new()
			scuff.name = "FloorWear_%d_%02d" % [lane_index + 1, stain_index + 1]
			var stain_mesh := PlaneMesh.new()
			stain_mesh.size = Vector2(
				_random.randf_range(1.2, 2.5),
				_random.randf_range(1.0, 2.2)
			)
			scuff.mesh = stain_mesh
			scuff.material_override = _scuff_material
			scuff.position = Vector3(lane_x + x_offset, floor_y + 0.025, z_position)
			scuff.rotation.y = _random.randf_range(-PI, PI)
			add_child(scuff)

		var rug_x: float = lane_x + (-3.7 if lane_index % 2 == 0 else 3.7)
		var rug_z: float = -3.0 if lane_index % 2 == 0 else 4.0
		var rug := MeshInstance3D.new()
		rug.name = "PatternedRug_%d" % (lane_index + 1)
		var rug_mesh := PlaneMesh.new()
		rug_mesh.size = Vector2(3.2, 4.4)
		rug.mesh = rug_mesh
		rug.material_override = _rug_material
		rug.position = Vector3(rug_x, floor_y + 0.035, rug_z)
		rug.rotation.y = _random.randf_range(-0.15, 0.15)
		add_child(rug)


func _create_department_vignettes() -> void:
	var stations: Array[Vector2] = [
		Vector2(-27.8, -23.0), Vector2(-20.2, 2.0), Vector2(-27.8, 15.0),
		Vector2(-8.2, 12.0), Vector2(-15.8, -8.0), Vector2(-8.2, -19.0),
		Vector2(3.8, -8.0), Vector2(-3.8, 6.0), Vector2(3.8, 18.0),
		Vector2(15.8, -17.0), Vector2(8.2, 0.0), Vector2(15.8, 13.0),
		Vector2(27.8, -22.0), Vector2(20.2, 0.0), Vector2(27.8, 17.0)
	]

	for lane_index: int in range(LANE_X.size()):
		var floor_y: float = FLOOR_HEIGHTS[lane_index]
		for station_index: int in range(3):
			var site: Vector2 = stations[lane_index * 3 + station_index]
			_add_vignette(
				Vector3(site.x, floor_y, site.y),
				_fabric_materials[(lane_index + station_index) % _fabric_materials.size()],
				station_index
			)


func _add_vignette(origin: Vector3, fabric: ShaderMaterial, variant: int) -> void:
	var display := Node3D.new()
	display.name = "LivingRoomVignette"
	display.position = origin
	add_child(display)

	var chair_size := Vector3(1.35, 0.72, 1.15)
	_add_box_prop("AccentChair", display, Vector3.ZERO, chair_size, fabric)
	_add_visual_box(display, Vector3(0.0, 0.74, -0.32), Vector3(1.38, 0.55, 0.22), fabric)
	_add_visual_box(display, Vector3(-0.58, 0.48, 0.0), Vector3(0.18, 0.58, 1.14), fabric)
	_add_visual_box(display, Vector3(0.58, 0.48, 0.0), Vector3(0.18, 0.58, 1.14), fabric)

	var cushion_color: Color = Color(0.94, 0.78, 0.48) if variant % 2 == 0 else Color(0.88, 0.84, 0.72)
	var cushion_material := _toon_material(cushion_color, FABRIC_TEXTURE, Vector2(3, 3))
	_add_visual_box(
		display,
		Vector3(0.0, 0.93, -0.12),
		Vector3(0.43, 0.3, 0.32),
		cushion_material,
		Vector3(0.0, 0.0, -0.12)
	)

	_add_box_prop(
		"SideTable",
		display,
		Vector3(1.3, 0.0, 0.08),
		Vector3(0.85, 0.58, 0.72),
		_wood_material
	)
	_add_visual_box(display, Vector3(1.3, 0.62, 0.08), Vector3(0.92, 0.12, 0.78), _wood_material)
	for leg_x: float in [-0.28, 0.28]:
		for leg_z: float in [-0.23, 0.23]:
			_add_visual_box(
				display,
				Vector3(1.3 + leg_x, 0.28, 0.08 + leg_z),
				Vector3(0.08, 0.52, 0.08),
				_wood_material
			)

	var plant_x: float = -1.35
	var plant_z: float = 0.8
	_add_cylinder_prop(
		"PlantPot",
		display,
		Vector3(plant_x, 0.0, plant_z),
		0.28,
		0.48,
		_wood_material
	)
	var leaf_material := _toon_material(Color(0.24, 0.48, 0.29), null, Vector2.ONE)
	for leaf_index: int in range(3):
		var leaf := SphereMesh.new()
		leaf.radius = 0.32
		leaf.height = 0.82
		var leaves := MeshInstance3D.new()
		leaves.name = "PlantLeaves"
		leaves.mesh = leaf
		leaves.material_override = leaf_material
		leaves.position = Vector3(
			plant_x + (float(leaf_index) - 1.0) * 0.2,
			1.0 + (0.12 if leaf_index == 1 else 0.0),
			plant_z
		)
		display.add_child(leaves)

	_add_floor_lamp(display, Vector3(1.35, 0.0, -0.95), variant)
	_add_billboard(
		origin + Vector3(0.0, 1.55, 1.0),
		0.0,
		Vector2(0.48, 0.36),
		_price_material,
		origin.y
	)


func _add_floor_lamp(parent: Node3D, position: Vector3, variant: int) -> void:
	var lamp_base := CylinderMesh.new()
	lamp_base.top_radius = 0.2
	lamp_base.bottom_radius = 0.27
	lamp_base.height = 0.12
	var base := MeshInstance3D.new()
	base.mesh = lamp_base
	base.material_override = _wood_material
	base.position = position + Vector3(0.0, 0.06, 0.0)
	parent.add_child(base)

	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.045
	stem_mesh.bottom_radius = 0.06
	stem_mesh.height = 1.45
	var stem := MeshInstance3D.new()
	stem.mesh = stem_mesh
	stem.material_override = _wood_material
	stem.position = position + Vector3(0.0, 0.82, 0.0)
	parent.add_child(stem)

	var shade_mesh := SphereMesh.new()
	shade_mesh.radius = 0.36
	shade_mesh.height = 0.48
	var shade_material := _toon_material(
		Color(0.92, 0.72, 0.39) if variant % 2 == 0 else Color(0.88, 0.88, 0.8),
		null,
		Vector2.ONE
	)
	var shade := MeshInstance3D.new()
	shade.mesh = shade_mesh
	shade.material_override = shade_material
	shade.position = position + Vector3(0.0, 1.63, 0.0)
	parent.add_child(shade)

	var lamp_body := StaticBody3D.new()
	lamp_body.name = "FloorLampCollision"
	lamp_body.position = position + Vector3(0.0, 0.0, 0.0)
	parent.add_child(lamp_body)
	var lamp_collision := CollisionShape3D.new()
	var lamp_shape := CylinderShape3D.new()
	lamp_shape.radius = 0.17
	lamp_shape.height = 1.75
	lamp_collision.shape = lamp_shape
	lamp_collision.position.y = 0.88
	lamp_body.add_child(lamp_collision)


func _add_sofa_details() -> void:
	var displays: Array[Vector3] = [
		Vector3(-24.0, 0.0, -13.0),
		Vector3(-12.0, 2.5, 21.0),
		Vector3(0.0, 1.5, -17.0),
		Vector3(12.0, 4.0, 20.0),
		Vector3(24.0, 5.0, -14.0)
	]

	for display_index: int in range(displays.size()):
		var fabric: ShaderMaterial = _fabric_materials[display_index % _fabric_materials.size()]
		for pillow_index: int in range(2):
			var pillow := BoxMesh.new()
			pillow.size = Vector3(0.5, 0.34, 0.34)
			var pillow_node := MeshInstance3D.new()
			pillow_node.name = "SofaAccentPillow"
			pillow_node.mesh = pillow
			pillow_node.material_override = fabric
			pillow_node.position = displays[display_index] + Vector3(
				-2.0 + float(pillow_index) * 0.62,
				0.95,
				displays[display_index].z - 0.4
			)
			add_child(pillow_node)


func _create_promo_boards() -> void:
	var signs: Array[Vector3] = [
		Vector3(-26.0, 3.2, 13.0),
		Vector3(-21.8, 3.1, -22.0),
		Vector3(-8.0, 5.7, -13.0),
		Vector3(-15.5, 5.6, 8.0),
		Vector3(4.0, 4.7, -23.0),
		Vector3(-4.0, 4.4, 14.0),
		Vector3(15.0, 7.0, 8.0),
		Vector3(8.5, 6.7, -17.0),
		Vector3(26.0, 7.9, 15.0),
		Vector3(21.5, 7.7, -6.0)
	]
	var floor_heights: Array[float] = [0.0, 0.0, 2.5, 2.5, 1.5, 1.5, 4.0, 4.0, 5.0, 5.0]

	for sign_index: int in range(signs.size()):
		var texture_material: StandardMaterial3D = (
			_sale_material if sign_index % 3 == 0 else _department_material
		)
		var facing: float = PI * 0.5 if sign_index % 2 == 0 else -PI * 0.5
		_add_billboard(
			signs[sign_index],
			facing,
			Vector2(2.6, 1.15),
			texture_material,
			floor_heights[sign_index]
		)


func _add_box_prop(
	prop_name: String,
	parent: Node3D,
	base_position: Vector3,
	size: Vector3,
	material: Material
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = prop_name
	body.position = base_position
	parent.add_child(body)

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)
	_add_visual_box(body, Vector3(0.0, size.y * 0.5, 0.0), size, material)
	return body


func _add_box_collision(base_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = base_position
	add_child(body)
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)


func _add_visual_box(
	parent: Node3D,
	position: Vector3,
	size: Vector3,
	material: Material,
	rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation = rotation
	parent.add_child(instance)
	return instance


func _add_cylinder_prop(
	prop_name: String,
	parent: Node3D,
	base_position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> void:
	var body := StaticBody3D.new()
	body.name = prop_name
	body.position = base_position
	parent.add_child(body)

	var collider := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = radius
	cylinder_shape.height = height
	collider.shape = cylinder_shape
	collider.position.y = height * 0.5
	body.add_child(collider)

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 1.15
	mesh.bottom_radius = radius * 0.82
	mesh.height = height
	var pot := MeshInstance3D.new()
	pot.mesh = mesh
	pot.material_override = material
	pot.position.y = height * 0.5
	body.add_child(pot)


func _add_billboard(
	position: Vector3,
	yaw: float,
	size: Vector2,
	material: StandardMaterial3D,
	support_floor_y: float = -1.0
) -> void:
	var sign_mesh := QuadMesh.new()
	sign_mesh.size = size
	var billboard := MeshInstance3D.new()
	billboard.mesh = sign_mesh
	billboard.material_override = material
	billboard.position = position
	billboard.rotation.y = yaw
	add_child(billboard)

	var support_height: float = position.y - size.y * 0.5 - support_floor_y
	if support_height <= 0.0:
		return
	var sign_right: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, yaw)
	for support_side: float in [-1.0, 1.0]:
		_add_box_visual(
			self,
			position + sign_right * (size.x * 0.42 * support_side)
			- Vector3(0.0, size.y * 0.5 + support_height * 0.5, 0.0),
			Vector3(0.12, support_height, 0.12),
			_wood_material
		)


func _add_image_material(
	texture: Texture2D,
	tint: Color,
	use_alpha: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if use_alpha:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return material


func _toon_material(
	color: Color,
	texture: Texture2D,
	texture_scale: Vector2
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TOON_SHADER
	material.set_shader_parameter("albedo_color", color)
	material.set_shader_parameter("albedo_texture", texture)
	material.set_shader_parameter("use_albedo_texture", texture != null)
	material.set_shader_parameter("texture_scale", texture_scale)
	return material
