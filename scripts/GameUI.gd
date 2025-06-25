# res://scripts/GameUI.gd
extends Control

@onready var money_label        : Label       = $MoneyLabel
@onready var wave_label         : Label       = $WaveLabel
@onready var progress_bar       : ProgressBar = $WaveProgress
@onready var start_button       : Button      = $StartWaveButton
@onready var fast_forward_button: Button      = $FastForwardButton

var money: int = 0
var wm   : Node = null

func _ready() -> void:
	# WaveManager now lives under GameLayer ▶ WaveManager
	wm = get_tree().current_scene.get_node("GameLayer/WaveManager")
	if wm == null:
		push_error("GameUI: could not find WaveManager at GameLayer/WaveManager")
		return

	# Connect WaveManager signals
	wm.connect("wave_started",    Callable(self, "_on_wave_started"))
	wm.connect("enemy_spawned",   Callable(self, "_on_enemy_spawned"))
	wm.connect("enemy_died",      Callable(self, "_on_enemy_died"))
	wm.connect("enemy_hit_queen", Callable(self, "_on_enemy_hit_queen"))

	# Hook up buttons
	start_button.connect("pressed", Callable(wm, "start_wave"))
	fast_forward_button.connect("toggled", Callable(self, "_on_fast_forward_toggled"))

func _on_wave_started(wave_number: int) -> void:
	wave_label.text        = "Wave %d" % wave_number
	progress_bar.max_value = wm.max_alive
	progress_bar.value     = wm.alive_count

func _on_enemy_spawned(alive: int, max_alive: int) -> void:
	progress_bar.max_value = max_alive
	progress_bar.value     = alive

func _on_enemy_died(enemy: Node, alive: int) -> void:
	money += enemy.gold_drop
	money_label.text = "$%d" % money
	progress_bar.value = alive

func _on_enemy_hit_queen(enemy: Node, alive: int) -> void:
	get_tree().current_scene.get_node("Queen").take_damage(enemy.damage)
	progress_bar.value = alive

func _on_fast_forward_toggled(pressed: bool) -> void:
	Engine.time_scale = 2.0 if pressed else 1.0
