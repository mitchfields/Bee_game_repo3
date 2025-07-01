# res://scripts/HexGridOverlay.gd
extends Node2D

@export var line_color        := Color(1, 1, 1, 0.2)
@export var line_width        := 1.0

@export var fill_enabled      := false
@export var fill_color        := Color(1, 1, 1, 0.05)

@export var anim_enabled      := false
@export var anim_color        := Color(1, 0, 0, 0.1)
@export var anim_speed        := 1.0

@export var noise_scale       := 0.5
@export var noise_frequency   := 0.1
@export var noise_octaves     := 3
@export var noise_lacunarity  := 2.0
@export var noise_gain        := 0.5

@export var use_radius        := false
@export var radius            := 8

var world = null
var noise = null
var _time = 0.0

func _ready():
	world = get_parent()
	# Initialize FastNoiseLite for simplex noise
	noise = FastNoiseLite.new()
	noise.noise_type        = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency         = noise_frequency
	noise.fractal_octaves   = noise_octaves
	noise.fractal_lacunarity= noise_lacunarity
	noise.fractal_gain      = noise_gain
	set_process(true)

func _process(delta):
	_time += delta
	queue_redraw()

func _draw():
	if world == null:
		return
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return

	var min_q:int
	var max_q:int
	var min_r:int
	var max_r:int

	if use_radius:
		min_q = -radius
		max_q = radius
		min_r = -radius
		max_r = radius
	else:
		var vs = get_viewport().size
		var hw = vs.x * 0.5 * cam.zoom.x
		var hh = vs.y * 0.5 * cam.zoom.y
		var origin = cam.global_position
		var tl = origin + Vector2(-hw, -hh)
		var br = origin + Vector2( hw,  hh)
		var a1 = world.world_to_axial(tl)
		var a2 = world.world_to_axial(br)
		min_q = int(floor(min(a1.x, a2.x))) - 2
		max_q = int(ceil (max(a1.x, a2.x))) + 2
		min_r = int(floor(min(a1.y, a2.y))) - 2
		max_r = int(ceil (max(a1.y, a2.y))) + 2

	for q in range(min_q, max_q + 1):
		for r in range(min_r, max_r + 1):
			if use_radius and hex_distance(Vector2(q, r), Vector2.ZERO) > radius:
				continue

			var center = world.axial_to_world(Vector2(q, r))
			var pts = []
			for i in range(6):
				var ang = deg_to_rad(60 * i)
				pts.append(center + Vector2(cos(ang), sin(ang)) * world.hex_size)
			pts.append(pts[0])

			if fill_enabled or anim_enabled:
				var c = fill_color
				if anim_enabled and noise:
					var n = noise.get_noise_3d(q * noise_scale, r * noise_scale, _time * anim_speed)
					var t = clamp((n + 1.0) * 0.5, 0.0, 1.0)
					c = fill_color.lerp(anim_color, t)
				draw_colored_polygon(pts, c)

			draw_polyline(pts, line_color, line_width)

func hex_distance(a: Vector2, b: Vector2) -> int:
	var dx = a.x - b.x
	var dy = a.y - b.y
	return int((abs(dx) + abs(dx + dy) + abs(dy)) * 0.5)
