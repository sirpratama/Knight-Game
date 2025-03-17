extends CharacterBody2D
@onready var playersprite = $AnimatedSprite2D
@onready var quest_ui = $Camera2D/quest_ui
@onready var gameover = $Camera2D/Gameover
@onready var youwin = $Camera2D/youwin
var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true
var attack_inprogress = false
var npc_in_range = false
var dialogue_active = false
var quest_input_pressed = false
var enemy_attack_damge = 5
const speed = 300.0

func _ready():
	# Connect to the dialogue ended signal
	if DialogueManager.has_signal("dialogue_ended"):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	else:
		print("WARNING: DialogueManager doesn't have dialogue_ended signal. Movement may not restore after dialogue.")

func get_input():
	if dialogue_active == false:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		velocity = input_direction * speed
		if input_direction:
			playersprite.play("run")
		else:
			playersprite.play("idle")
		
		if input_direction.x < 0:
			playersprite.flip_h = true
		elif input_direction.x > 0:
			playersprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		playersprite.play("idle")

func _physics_process(_delta):
	
	if global.goblin_quest_completed == true and global.goblins_remaining <= 0:
		youwin.visible = true
		quest_ui.visible = false
		dialogue_active = true # Keep player from moving
		playersprite.play("idle")
		return
	
	if player_alive:
		attack()
		update_health()
		quest_ui.visible = global.goblin_quest_accepted and global.goblin_quest_completed == false
		gameover.visible = false
		youwin.visible = false
		if attack_inprogress == false:
			get_input()
			move_and_slide()
	
		enemy_attack()
	else:
		gameover.visible = true
	
	if health <= 0 and player_alive:
		velocity = Vector2(0,0)
		player_alive = false # Add ui game over screen and a start over button
		health = 0
		playersprite.play("dead")
		await get_tree().create_timer(100000000000).timeout
		gameover.visible = true
		self.queue_free()
		
		
	if npc_in_range == true:
		if Input.is_action_just_pressed("quest") and not dialogue_active and not quest_input_pressed:
			print("Quest button pressed")
			quest_input_pressed = true  # Set flag to prevent multiple activations
			dialogue_active = true
			velocity = Vector2.ZERO     # Immediately stop movement
			DialogueManager.show_example_dialogue_balloon(load("res://main.dialogue"), "main")
	
	if global.potions_touched == true:
		if health <= 80:
			health = health + 20
			global.potions_touched = false
		elif health == 85:
			health = health + 15
			global.potions_touched = false
		elif health == 90:
			health = health + 10
			global.potions_touched = false
		elif health == 95:
			health = health + 5
			global.potions_touched = false
		else:
			health = health + 0
			global.potions_touched = false

func _on_dialogue_ended(_resource = null):
	print("Dialogue ended, restoring player movement")
	dialogue_active = false  # This re-enables movement in get_input()
	velocity = Vector2.ZERO  # Reset velocity to prevent sliding
	await get_tree().create_timer(0.5).timeout # Delay
	quest_input_pressed = false
	if global.goblin_quest_accepted == true:
		quest_ui.visible = true
	elif global.goblin_quest_completed == true:
		quest_ui.visible = false
		youwin.visible = true
		velocity = Vector2.ZERO

func player():
	pass

func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_inattack_range = true

func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_inattack_range = false
		
func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown == true:
		health = health - enemy_attack_damge
		enemy_attack_cooldown = false
		$attack_cooldown.start()
		print(health)

func _on_attack_cooldown_timeout():
	enemy_attack_cooldown = true

func attack():
	# Only allow attacks if dialogue is not active
	if Input.is_action_just_pressed("attack") and not dialogue_active:
		global.player_current_attack = true
		attack_inprogress = true
		playersprite.play("attack")
		$deal_attack_timer.start()

func _on_deal_attack_timer_timeout() -> void:
	$deal_attack_timer.stop()
	global.player_current_attack = false
	attack_inprogress = false
	
func update_health():
	var healthbar = $healthbar
	healthbar.value = health
	
	if health >= 100:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_regen_timer_timeout() -> void:
	if health < 100:
		health = health + 10
		if health > 100:
			health = 100
	if health <= 0:
		health = 0

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("npc"):
		npc_in_range = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("npc"):
		npc_in_range = false
