# res://ShopManager.gd
class_name ShopManager
extends HBoxContainer

@export var pool: Array[PackedScene] = []
@export var slot_count: int = 5
@export var slot_spacing: float = 80.0

var slots: Array[TextureButton] = []
var slot_data: Array[PackedScene] = []

func _ready() -> void:
	# Gather all TextureButton children
	for child in get_children():
		if child is TextureButton:
			slots.append(child)
	reroll_shop()

func reroll_shop() -> void:
	if pool.size() == 0:
		push_error("ShopManager: pool is empty! Drag some scenes into the pool export.")
		return
	slot_data.clear()
	var choices = pool.duplicate()
	var count = min(slot_count, choices.size())
	for i in range(count):
		var idx = randi() % choices.size()
		slot_data.append(choices[idx])
		choices.remove_at(idx)
	update_slots()

func update_slots() -> void:
	# Assign each slot its scene and preview texture
	for i in range(slot_data.size()):
		var slot = slots[i]
		var scene = slot_data[i]
		# Temporarily instantiate to get its Sprite2D texture
		var inst = scene.instantiate() as Node2D
		if inst.has_node("Sprite2D"):
			var sprite = inst.get_node("Sprite2D") as Sprite2D
			slot.texture_normal = sprite.texture
		inst.queue_free()
		slot.scene_to_spawn = scene
	reposition_slots()

func reposition_slots() -> void:
	# Center slots with fixed spacing, tweening into place
	var total_w = (slots.size() - 1) * slot_spacing
	var start_x = -total_w * 0.5
	for i in range(slots.size()):
		var slot = slots[i]
		var target_pos = Vector2(start_x + i * slot_spacing, slot.position.y)
		var tw = get_tree().create_tween()
		var step = tw.tween_property(slot, "position", target_pos, 0.3)
		step.set_trans(Tween.TRANS_BOUNCE)
		step.set_ease(Tween.EASE_OUT)

func on_slot_dragged_off(dragged_slot: TextureButton) -> void:
	var idx = slots.find(dragged_slot)
	if idx != -1:
		slots.remove_at(idx)
		slot_data.remove_at(idx)
		update_slots()

func on_slot_returned_back(dragged_slot: TextureButton, drop_index: int) -> void:
	drop_index = clamp(drop_index, 0, slots.size())
	slots.insert(drop_index, dragged_slot)
	slot_data.insert(drop_index, dragged_slot.scene_to_spawn)
	add_child(dragged_slot)
	update_slots()
