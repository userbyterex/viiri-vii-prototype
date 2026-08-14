extends Control

# Data state
var vesper_hp: int = 100
var vesper_max_hp: int = 100
var vesper_limit: int = 0
var infection_level: int = 15

var enemy_hp: int = 250
var enemy_max_hp: int = 250

@onready var log_label: Label = $Panel/MarginContainer/VBox/LogLabel
@onready var vesper_hp_bar: TextureProgressBar = $Panel/MarginContainer/VBox/HBox/VesperPanel/VesperHP
@onready var infection_bar: ProgressBar = $Panel/MarginContainer/VBox/HBox/VesperPanel/InfectionBar
@onready var limit_bar: ProgressBar = $Panel/MarginContainer/VBox/HBox/VesperPanel/LimitBar
@onready var enemy_hp_bar: ProgressBar = $Panel/MarginContainer/VBox/HBox/EnemyPanel/EnemyHP

func _ready() -> void:
	append_log("System initialized: Oakhaven Prime - Reactor 03 Perimeter.")
	append_log("Vesper engaged Biomechanical Sentinel.")
	update_ui()

func append_log(text: String) -> void:
	if log_label:
		log_label.text += text + "\n"

func update_ui() -> void:
	$Panel/MarginContainer/VBox/HBox/VesperPanel/HPText.text = "HP: " + str(vesper_hp) + " / " + str(vesper_max_hp)
	$Panel/MarginContainer/VBox/HBox/EnemyPanel/EnemyHPText.text = "Sentinel HP: " + str(enemy_hp) + " / " + str(enemy_max_hp)
	$Panel/MarginContainer/VBox/HBox/VesperPanel/InfectionText.text = "Parasite Infection: " + str(infection_level) + "%"
	$Panel/MarginContainer/VBox/HBox/VesperPanel/LimitText.text = "Limit Break: " + str(vesper_limit) + "%"

func _on_attack_button_pressed() -> void:
	if enemy_hp <= 0:
		return
	var dmg = randi_range(18, 25)
	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 15)
	append_log("Vesper fires Heavy Sidearm for " + str(dmg) + " damage!")
	check_enemy_turn()

func _on_skill_button_pressed() -> void:
	if enemy_hp <= 0:
		return
	var dmg = randi_range(35, 50)
	infection_level = min(100, infection_level + 10)
	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 25)
	append_log("Vesper casts [Tech-Pulse Parasite]! Deals " + str(dmg) + " damage. (+10% Infection)")
	check_enemy_turn()

func _on_limit_button_pressed() -> void:
	if enemy_hp <= 0 or vesper_limit < 100:
		append_log("Limit Break not ready yet!")
		return
	var dmg = randi_range(90, 120)
	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = 0
	append_log(">>> CORE DESPERTAR: Vesper unleash PARASITE OVERDRIVE for " + str(dmg) + " MASSIVE DAMAGE!")
	check_enemy_turn()

func check_enemy_turn() -> void:
	update_ui()
	if enemy_hp <= 0:
		append_log("\n*** VICTORY! Biomechanical Sentinel destroyed! ***")
		return
	
	# Enemy attacks back
	var enemy_dmg = randi_range(10, 18)
	vesper_hp = max(0, vesper_hp - enemy_dmg)
	append_log("Sentinel counters with Plasma Cannon for " + str(enemy_dmg) + " damage.")
	if vesper_hp <= 0:
		append_log("\n*** GAME OVER - Vesper was defeated ***")
	update_ui()
