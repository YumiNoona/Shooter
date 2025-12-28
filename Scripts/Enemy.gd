extends CharacterBody2D
class_name Enemy

@export var move_speed := 400.0

@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: HealthBar = $HealthBar
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var area_2d: Area2D = $Area2D

@export var contact_damage: float = 1.0
@export var damage_cooldown: float = 1.5  # Time in seconds between damage ticks

var can_move := true
var players_in_contact: Array[Player] = []
var damage_timers: Dictionary = {}

func _physics_process(_delta: float) -> void:
	var player_direction = GameManager.player.global_position - global_position
	var direction = player_direction.normalized()
	var movement = direction * move_speed
	velocity = movement
	
	
	if player_direction.length() <= 120:
		return
	
	if not can_move:
		return
	
	move_and_slide()
	anim_sprite.flip_h = true if velocity.x < 0 else false

func _on_health_component_on_damaged() -> void:
	var health_value := health_component.current_health / health_component.max_health
	health_bar.set_value(health_value)
	anim_sprite.material = GameManager.HIT_MATERIAL
	await get_tree().create_timer(0.3).timeout
	anim_sprite.material = null

func _on_health_component_on_defeated() -> void:
	can_move = false
	anim_sprite.play("Death")
	collision_shape_2d.set_deferred("disabled", true)
	GameManager.create_coin(global_position)
	health_bar.hide()
	
	# Clean up all damage timers
	for timer in damage_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	damage_timers.clear()
	players_in_contact.clear()
	
	await anim_sprite.animation_finished
	GameManager.on_enemy_died.emit()
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	var player = body as Player
	if not player:
		return


	if player not in players_in_contact:
		players_in_contact.append(player)
		deal_contact_damage(player)
		start_damage_timer(player)

func _on_area_2d_body_exited(body: Node2D) -> void:
	var player = body as Player
	if not player:
		return
	

	if player in players_in_contact:
		players_in_contact.erase(player)

		if player in damage_timers:
			var timer = damage_timers[player]
			if is_instance_valid(timer):
				timer.queue_free()
			damage_timers.erase(player)

func start_damage_timer(player: Player) -> void:
	var timer = Timer.new()
	timer.wait_time = damage_cooldown
	timer.one_shot = false
	timer.timeout.connect(func(): deal_contact_damage(player))
	add_child(timer)
	timer.start()
	damage_timers[player] = timer

var last_damage_time: float = 0.0

func deal_contact_damage(player: Player) -> void:
	if not is_instance_valid(player) or player not in players_in_contact:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time >= damage_cooldown:
		player.health_component.take_damage(contact_damage)
		last_damage_time = current_time
	GameManager.play_damage_text(player.global_position, int(contact_damage))
