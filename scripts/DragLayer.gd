# res://DragLayer.gd
extends Control

var dragging_slot: TextureButton = null
var origin_shop: ShopManager = null
var origin_index: int = -1

func start_drag(slot: TextureButton, shop_manager: ShopManager, index: int) -> void:
	dragging_slot = slot
	origin_shop   = shop_manager
	origin_index  = index
	# Remove the slot from its HBoxContainer and add it under DragLayer
	slot.get_parent().remove_child(slot)
	add_child(slot)
	# Make it semi‐transparent while dragging
	slot.modulate = Color(1, 1, 1, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if dragging_slot == null:
		return

	if event is InputEventMouseMotion:
		# Follow the cursor
		dragging_slot.global_position = event.position

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var screen_h = get_viewport().get_visible_rect().size.y
		if event.position.y < screen_h * 0.9:
			# Dropped on the grid: spawn and remove the slot
			get_tree().current_scene._spawn_hex(dragging_slot.scene_to_spawn)
			origin_shop.on_slot_dragged_off(dragging_slot)
			dragging_slot.queue_free()
		else:
			# Dropped back in shop: return slot to its origin
			origin_shop.on_slot_returned_back(dragging_slot, origin_index)

		# Reset dragging state
		dragging_slot = null
		origin_shop   = null
		origin_index  = -1

		# Prevent further input handling this event
		get_tree().set_input_as_handled()
