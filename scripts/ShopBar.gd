# res://scripts/ShopBar.gd
extends Node2D

@export var item_scenes: Array[PackedScene] = []
@export var max_slots: int       = 5
@export var bar_width: float     = 600.0
@export var y_offset: float      = 0.0
@export var drop_back_ratio: float = 0.1  # bottom 10% drop-back area

var items: Array[Node2D] = []
var base_spacing: float  = 0.0
var reroll_cost: int     = 2

@onready var reroll_button: Button = $RerollButton

func _ready() -> void:
	randomize()
	if max_slots > 1:
		base_spacing = bar_width / float(max_slots - 1)
	else:
		base_spacing = 0.0

	reroll_button.text = "Reroll ($%d)" % reroll_cost
	reroll_button.connect("pressed", Callable(self, "_on_reroll_pressed"))

	_spawn_shop_items()

func _spawn_shop_items() -> void:
	# Clear out any old items
	for it in items:
		it.queue_free()
	items.clear()

	var available = item_scenes.size()
	if available == 0:
		push_error("ShopBar: no scenes assigned to item_scenes")
		return

	# Spawn exactly max_slots (allow repeats)
	for i in range(max_slots):
		var scene = item_scenes[randi() % available]
		var inst  = preload("res://scenes/ShopItem.tscn").instantiate() as Node2D
		inst.set("spawn_scene", scene)
		inst.scale    = Vector2.ONE
		inst.position = _anchor_pos(i, max_slots)
		add_child(inst)
		items.append(inst)

	_reflow_items()

func _anchor_pos(index: int, count: int) -> Vector2:
	if count <= 1:
		return Vector2(0, y_offset)
	# Pyramid-collapse spacing: shrinks as count decreases
	var offset_x = -base_spacing * float(count - 1) * 0.5 + base_spacing * index
	return Vector2(offset_x, y_offset)

func _reflow_items() -> void:
	var count = items.size()
	for i in range(count):
		var it = items[i]
		if it == null:
			continue
		var target = _anchor_pos(i, count)
		var tw     = create_tween()
		var op     = tw.tween_property(it, "position", target, 0.3)
		if op:
			op.set_trans(Tween.TRANS_BOUNCE)
			op.set_ease(Tween.EASE_OUT)

func _on_item_dropped(item: Node2D, drop_pos: Vector2) -> void:
	var screen_h = get_viewport().get_visible_rect().size.y
	if drop_pos.y < screen_h * (1.0 - drop_back_ratio):
		# PURCHASE: remove and collapse
		get_tree().current_scene._spawn_hex(item.get("spawn_scene"))
		items.erase(item)
		item.queue_free()
	else:
		# RETURN: if accidentally removed, re-add
		if not items.has(item):
			items.append(item)
	_reflow_items()

func _on_reroll_pressed() -> void:
	var available = item_scenes.size()
	if available == 0:
		return

	var new_items: Array[Node2D] = []
	for i in range(max_slots):
		var old_item: Node2D = null
		if i < items.size():
			old_item = items[i]

		# Skip frozen items (ShopItem.gd must define `var frozen := false`)
		var keep_frozen := false
		if old_item != null:
			keep_frozen = old_item.frozen

		if keep_frozen:
			new_items.append(old_item)
		else:
			# remove old
			if old_item:
				old_item.queue_free()

			# spawn new at zero scale, at its slot
			var scene = item_scenes[randi() % available]
			var inst  = preload("res://scenes/ShopItem.tscn").instantiate() as Node2D
			inst.set("spawn_scene", scene)
			inst.scale    = Vector2.ZERO
			inst.position = _anchor_pos(i, max_slots)
			add_child(inst)
			new_items.append(inst)

			# “ploop” scale-in with staggered delay
			var tw = create_tween()
			tw.tween_interval(0.1 * i)
			var op = tw.tween_property(inst, "scale", Vector2.ONE, 0.25)
			if op:
				op.set_trans(Tween.TRANS_BOUNCE)
				op.set_ease(Tween.EASE_OUT)
	# replace items list
	items = new_items

	# increase cost and update button text
	reroll_cost += 1
	reroll_button.text = "Reroll ($%d)" % reroll_cost

	_reflow_items()
