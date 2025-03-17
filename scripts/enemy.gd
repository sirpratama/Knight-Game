extends CharacterBody2D

const speed = 150
@export var player = Node2D
@export var detection_radius = 300
@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@onready var detection_area = $DetectionArea as Area2D
@onready var enemysprite = $AnimatedSprite2D
var player_detected = false
var player_inattack_zone = false
var health = 100
var enemy_alive = true
var attack_inprogress = false
var player_attack_cooldown = true
var player_attack_damage = 15

func _ready():
	# Set detection radius for the existing DetectionArea node
	var collision = $DetectionArea/CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = detection_radius
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(_delta: float) -> void:
	
	deal_damage()
	update_health()
	
	if player_detected:
		var dir = to_local(nav_agent.get_next_path_position()).normalized()
		velocity = dir * speed
		move_and_slide()
		
		if player.position.x < position.x:
			enemysprite.flip_h = true
		else:
			enemysprite.flip_h = false
	else:
		velocity = Vector2.ZERO

func make_path() -> void:
	nav_agent.target_position = player.global_position

func _on_timer_timeout() -> void:
	if player_detected:
		make_path()

func _on_detection_area_body_entered(body):
	if body == player:
		enemysprite.play("run")
		player_detected = true
		make_path()

func _on_detection_area_body_exited(body):
	enemysprite.play("idle")
	if body == player:
		player_detected = false

func enemy():
	pass

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true
		global.enemy_current_attack = true
		attack_inprogress = true
		enemysprite.play("attack")
		$deal_attack_timer.start()

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false
		
func deal_damage():
	if global.buff_potion_touched == true:
		player_attack_damage = 50
	if player_inattack_zone and global.player_current_attack == true and player_attack_cooldown:
		health = health - player_attack_damage
		player_attack_cooldown = false
		print("Goblin has been attacked ", health)
		$attack_cooldown.start()
		if health <= 0:
			print(global.goblins_remaining)
			
			if global.goblin_quest_accepted and global.goblin_quest_completed == false:
				
				if global.goblins_remaining <= 0:
					global.goblin_quest_completed = true
					print("Quest completed! All goblins defeated.")
					
			enemysprite.play("dead")
			await enemysprite.animation_finished
			self.queue_free()
			global.goblins_remaining -= 0.5 # I set this to 0.5 because the deal damage increment 2 times


func _on_deal_attack_timer_timeout() -> void:
	$deal_attack_timer.stop()
	global.player_current_attack = false
	attack_inprogress = false
	player_inattack_zone = false


func _on_attack_cooldown_timeout() -> void:
	player_attack_cooldown = true

func update_health():
	var healthbar = $healthbar
	healthbar.value = health
	
	if health >= 100:
		healthbar.visible = false
	else:
		healthbar.visible = true
