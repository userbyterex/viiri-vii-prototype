extends Node3D

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
var is_player_turn: bool = true

# ======================
# NODE REFERENCES
# ======================
@onready var log_label: Label = $UI/Panel/Margin/VBox/LogLabel
@onready var hp_text: Label = $UI/Panel/Margin/VBox/HBox/VesperInfo/HPText
@onready var infection_text: Label = $UI/Panel/Margin/VBox/HBox/VesperInfo/InfectionText
@onready var limit_text: Label = $UI/Panel/Margin/VBox/HBox/VesperInfo/LimitText
@onready var enemy_hp_text: Label = $UI/Panel/Margin/VBox/HBox/EnemyInfo/EnemyHPText

@onready var attack_btn: Button = $UI/Panel/Margin/VBox/HBox/VesperInfo/AttackButton
@onready var skill_btn: Button = $UI/Panel/Margin/VBox/HBox/VesperInfo/SkillButton
@onready var limit_btn: Button = $UI/Panel/Margin/VBox/HBox/VesperInfo/LimitButton

@onready var vesper: Node3D = $Characters/Vesper
@onready var sentinel: Node3D = $Characters/Sentinel
@onready var camera: Camera3D = $Camera3D


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
		# Auto-scroll
		await get_tree().process_frame


func update_ui() -> void:
	hp_text.text = "HP: %d / %d" % [vesper_hp, vesper_max_hp]
	infection_text.text = "Parasite Infection: %d%%" % infection_level
	limit_text.text = "Limit Break: %d%%" % vesper_limit
	enemy_hp_text.text = "Sentinel HP: %d / %d" % [enemy_hp, enemy_max_hp]

	if infection_level >= 70:
		infection_text.modulate = Color(1.0, 0.35, 0.35)
	elif infection_level >= 40:
		infection_text.modulate = Color(1.0, 0.7, 0.3)
	else:
		infection_text.modulate = Color(0.6, 0.9, 1.0)


func _update_buttons() -> void:
	var can_act = not combat_ended and enemy_hp > 0 and vesper_hp > 0 and is_player_turn
	attack_btn.disabled = not can_act
	skill_btn.disabled = not can_act
	limit_btn.disabled = not can_act or vesper_limit < 100


func _on_attack_button_pressed() -> void:
	if combat_ended or not is_player_turn:
		return

	is_player_turn = false
	_update_buttons()

	var base_dmg = randi_range(16, 24)
	var bonus = int(infection_level * 0.25)
	var dmg = base_dmg + bonus

	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 12)
	infection_level = min(100, infection_level + 3)

	# Simple attack animation feedback
	_play_attack_feedback(vesper)

	append_log("Vesper slashes with his plasma-edged blade for %d damage." % dmg)
	if bonus > 0:
		append_log("  → Parasite resonance added +%d damage." % bonus)

	await get_tree().create_timer(0.6).timeout
	_resolve_turn()


func _on_skill_button_pressed() -> void:
	if combat_ended or not is_player_turn:
		return

	is_player_turn = false
	_update_buttons()

	var base_dmg = randi_range(32, 48)
	var bonus = int(infection_level * 0.55)
	var dmg = base_dmg + bonus

	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = min(100, vesper_limit + 22)
	infection_level = min(100, infection_level + 14)

	_play_attack_feedback(vesper)

	append_log("Vesper channels the parasite — [Parasite Slash] hits for %d damage!" % dmg)
	append_log("  → Infection rises sharply (+14%)")

	await get_tree().create_timer(0.7).timeout
	_resolve_turn()


func _on_limit_button_pressed() -> void:
	if combat_ended or vesper_limit < 100 or not is_player_turn:
		append_log("Core Despertar is not ready.")
		return

	is_player_turn = false
	_update_buttons()

	var dmg = randi_range(95, 135) + int(infection_level * 0.4)
	enemy_hp = max(0, enemy_hp - dmg)
	vesper_limit = 0
	infection_level = max(0, infection_level - 25)

	_play_attack_feedback(vesper, true)

	append_log("")
	append_log(">>> CORE DESPERTAR ACTIVATED <<<")
	append_log("Vesper's blade erupts with biomechanical energy!")
	append_log("PARASITE OVERDRIVE deals %d MASSIVE DAMAGE!" % dmg)
	append_log("  → Infection partially purged (-25%)")
	append_log("")

	await get_tree().create_timer(1.0).timeout
	_resolve_turn()


func _resolve_turn() -> void:
	update_ui()

	if enemy_hp <= 0:
		_victory()
		return

	# Enemy turn
	await get_tree().create_timer(0.4).timeout
	_enemy_attack()

	if vesper_hp <= 0:
		_defeat()
		return

	# High infection self-damage
	if infection_level >= 80:
		var self_dmg = randi_range(4, 9)
		vesper_hp = max(0, vesper_hp - self_dmg)
		append_log("The parasite rebels... Vesper takes %d damage from internal strain." % self_dmg)
		update_ui()
		if vesper_hp <= 0:
			_defeat()
			return

	is_player_turn = true
	_update_buttons()


func _enemy_attack() -> void:
	var dmg: int
	var msg: String

	_play_attack_feedback(sentinel)

	if enemy_hp < enemy_max_hp * 0.35:
		dmg = randi_range(18, 28)
		msg = "The Sentinel enters overload and fires a concentrated plasma burst for %d damage!" % dmg
	else:
		dmg = randi_range(11, 19)
		msg = "Biomechanical Sentinel retaliates with its plasma cannon for %d damage." % dmg

	vesper_hp = max(0, vesper_hp - dmg)
	append_log(msg)
	update_ui()


func _play_attack_feedback(character: Node3D, is_limit: bool = false) -> void:
	# Simple scale punch for feedback
	var original_scale = character.scale
	var tween = create_tween()
	var punch = 1.25 if is_limit else 1.12
	tween.tween_property(character, "scale", original_scale * punch, 0.08)
	tween.tween_property(character, "scale", original_scale, 0.15)


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
