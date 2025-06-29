# res://scripts/ShopBar.gd
extends Node2D

@export var item_scenes: Array[PackedScene] = []
@export var max_slots: int       = 5
@export var bar_width: float     = 600.0
@export var y_offset: float      = 0.0
@export var drop_back_ratio: float = 0.1  # bottom 10% = cancel area

var items: Array[Node2D] = []
var base_spacing: float  = 0.0
var reroll_cost: int     = 2

@onready var reroll_button: Button = $RerollButton

func _ready() -> void:
	randomize()
	base_spacing = bar_width / float(max_slots - 1) if max_slots > 1 else 0.0
	reroll_button.text = "Reroll ($%d)" % reroll_cost
	reroll_button.connect("pressed", Callable(self, "_on_reroll_pressed"))
	_spawn_shop_items()

func _spawn_shop_items() -> void:
	# Clear out any old items
	for it in items:
		it.queue_free()
	items.clear()

	if item_scenes.is_empty():
		push_error("ShopBar: no scenes assigned to item_scenes")
		return

	# Spawn exactly max_slots (allow repeats)
	for i in range(max_slots):
		var scene = item_scenes[randi() % item_scenes.size()]
		var inst  = preload("res://scenes/ShopItem.tscn").instantiate() as Node2D
		# tell the item which scene it will spawn
		inst.spawn_scene = scene
		# update its icon immediately
		if inst.has_method("update_icon"):
			inst.update_icon()
		inst.scale    = Vector2.ONE
		inst.position = _anchor_pos(i, max_slots)
		add_child(inst)
		items.append(inst)

	_reflow_items()

func _anchor_pos(index: int, count: int) -> Vector2:
	if count <= 1:
		return Vector2(0, y_offset)
	var offset_x = -base_spacing * float(count - 1) * 0.5 + base_spacing * index
	return Vector2(offset_x, y_offset)

func _reflow_items() -> void:
	var count = items.size()
	for i in range(count):
		var it = items[i]
		var tw = create_tween()
		tw.tween_property(it, "position", _anchor_pos(i, count), 0.3)\
		  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_item_dropped(item: Node2D, drop_pos: Vector2) -> void:
	var screen_h = get_viewport().get_visible_rect().size.y
	if drop_pos.y < screen_h * (1.0 - drop_back_ratio):
		# PURCHASE: remove and collapse
		get_tree().current_scene._spawn_hex(item.spawn_scene)
		items.erase(item)
		item.queue_free()
	else:
		# RETURN: if accidentally removed, re-add
		if not items.has(item):
			items.append(item)
	_reflow_items()

func _on_reroll_pressed() -> void:
	if item_scenes.is_empty():
		return

	var new_items: Array[Node2D] = []
	for i in range(max_slots):
		var old_item: Node2D = null
		if i < items.size():
			old_item = items[i]

		var keep_frozen: bool = old_item != null and old_item.frozen
		if keep_frozen:
			new_items.append(old_item)
		else:
			if old_item:
				old_item.queue_free()

			var scene = item_scenes[randi() % item_scenes.size()]
			var inst  = preload("res://scenes/ShopItem.tscn").instantiate() as Node2D
			inst.spawn_scene = scene
			if inst.has_method("update_icon"):
				inst.update_icon()
			inst.scale    = Vector2.ZERO
			inst.position = _anchor_pos(i, max_slots)
			add_child(inst)
			new_items.append(inst)

			var tw = create_tween()
			tw.tween_interval(0.1 * i)
			tw.tween_property(inst, "scale", Vector2.ONE, 0.25)\
			  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	items = new_items
	reroll_cost += 1
	reroll_button.text = "Reroll ($%d)" % reroll_cost
	_reflow_items()
