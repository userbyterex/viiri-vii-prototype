extends Control

# ======================
# CHARACTER STATE
# ======================
var vesper_hp: int = 100
var vesper_max_hp: int = 100
var vesper_limit: int = 0
var infection_level: int = 12

var enemy_hp: int = 280
var enemy_max_hp: int = 280

var combat_ended: bool = false

# ======================
# NODE REFERENCES
# ======================
@onready var log_label: Label = $Panel/MarginContainer/VBox/LogLabel
@onready var hp_text: Label = $Panel/MarginContainer/VBox/HBox/VesperPanel/HPText
@onready var infection_text: Label = $Panel/MarginContainer/VBox/HBox/VesperPanel/InfectionText
@onready var limit_text: Label = $Panel/MarginContainer/VBox/HBox/VesperPanel/LimitText
@onready var enemy_hp_text: Label = $Panel/MarginContainer/VBox/HBox/EnemyPanel/EnemyHPText

@onready var attack_btn: Button = $Panel/MarginContainer/VBox/HBox/VesperPanel/AttackButton
@onready var skill_btn: Button = $Panel/MarginContainer/VBox/HBox/VesperPanel/SkillButton
@onready var limit_btn: Button = $Panel/MarginContainer/VBox/HBox/VesperPanel/LimitButton


func _ready() -> void:
	append_log("[SYSTEM] Oakhaven Prime — Reactor Sector 03")
	append_log("[SYSTEM] Biomechanical signature detected.")
	append_log("")
	append_log("Vesper draws his blade. The parasite stirs beneath his skin.")
	append_log("────────────────────────────────────")
	update_ui()
	_update_buttons()


func append_log(text: String) -> void:
	if log_label:
		log_label.text += text + "\n"


func update_ui() -> void:
	hp_text.text = "HP: %d / %d" % [vesper_hp, vesper_max_hp]
	infection_text.text = "Parasite Infection: %d%%" % infection_level
	limit_text.text = "Limit Break: %d%%" % vesper_limit
	enemy_hp_text.text = "Sentinel HP: %d / %d" % [enemy_hp, enemy_max_hp]

	# Visual feedback for high infection
	if infection_level >= 70:
		infection_text.modulate = Color(1.0, 0.35, 0.35)
	elif infection_level >= 40:
		infection_text.modulate = Color(1.0, 0.7, 0.3)
	else:
		infection_text.modulate = Color(0.6, 0.9, 1.0)


func _update_buttons() -> void:
	var can_act = not combat_ended and enemy_hp > 0 and vesper_hp > 0
	attack_btn.disabled = not can_act
	skill_btn.disabled = not can_act
	limit_btn.disabled = not can_act or vesper_limit < 100


func _on_attack_button_pressed() -> void:
	if combat_ended:
		return

	var base_dmg = randi_range(16, 24)
	var bonus = int(infection_level * 0.25)
	var dmg = base_dmg + bonus

	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 12)
	infection_level = min(100, infection_level + 3)

	append_log("Vesper slashes with his plasma-edged blade for %d damage." % dmg)
	if bonus > 0:
		append_log("  → Parasite resonance added +%d damage." % bonus)

	_resolve_turn()


func _on_skill_button_pressed() -> void:
	if combat_ended:
		return

	var base_dmg = randi_range(32, 48)
	var bonus = int(infection_level * 0.55)
	var dmg = base_dmg + bonus

	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 22)
	infection_level = min(100, infection_level + 14)

	append_log("Vesper channels the parasite — [Parasite Slash] hits for %d damage!" % dmg)
	append_log("  → Infection rises sharply (+14%)")

	_resolve_turn()


func _on_limit_button_pressed() -> void:
	if combat_ended or vesper_limit < 100:
		append_log("Core Despertar is not ready.")
		return

	var dmg = randi_range(95, 135) + int(infection_level * 0.4)
	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = 0
	infection_level = max(0, infection_level - 25)  # Limit consumes some infection

	append_log("")
	append_log(">>> CORE DESPERTAR ACTIVATED <<<")
	append_log("Vesper's blade erupts with biomechanical energy!")
	append_log("PARASITE OVERDRIVE deals %d MASSIVE DAMAGE!" % dmg)
	append_log("  → Infection partially purged (-25%)")
	append_log("")

	_resolve_turn()


func _resolve_turn() -> void:
	update_ui()

	if enemy_hp <= 0:
		_victory()
		return

	# Enemy turn
	await get_tree().create_timer(0.35).timeout
	_enemy_attack()

	if vesper_hp <= 0:
		_defeat()
		return

	# Infection passive damage at high levels
	if infection_level >= 80:
		var self_dmg = randi_range(4, 9)
		vesper_hp = max(0, vesper_hp - self_dmg)
		append_log("The parasite rebels... Vesper takes %d damage from internal strain." % self_dmg)
		update_ui()
		if vesper_hp <= 0:
			_defeat()
			return

	_update_buttons()


func _enemy_attack() -> void:
	var dmg: int
	var msg: String

	if enemy_hp < enemy_max_hp * 0.35:
		# Desperate mode
		dmg = randi_range(18, 28)
		msg = "The Sentinel enters overload and fires a concentrated plasma burst for %d damage!" % dmg
	else:
		dmg = randi_range(11, 19)
		msg = "Biomechanical Sentinel retaliates with its plasma cannon for %d damage." % dmg

	vesper_hp = max(0, vesper_hp - dmg)
	append_log(msg)
	update_ui()


func _victory() -> void:
	combat_ended = true
	_update_buttons()
	append_log("")
	append_log("════════════════════════════════════")
	append_log("*** VICTORY ***")
	append_log("The Biomechanical Sentinel collapses in a shower of sparks and black fluid.")
	append_log("Vesper stands amidst the wreckage, blade still humming.")
	append_log("The parasite grows quieter... for now.")
	append_log("════════════════════════════════════")


func _defeat() -> void:
	combat_ended = true
	_update_buttons()
	append_log("")
	append_log("════════════════════════════════════")
	append_log("*** DEFEAT ***")
	append_log("Vesper falls to his knees. The parasite surges out of control...")
	append_log("Darkness takes him.")
	append_log("════════════════════════════════════")
