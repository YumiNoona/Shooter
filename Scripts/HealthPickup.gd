extends Area2D

@export var heal_amount: float = 10.0
@export var lifetime: float = 10.0
@export var move_speed: float = 150.0
@export var attract_distance: float = 200.0

var target: Node2D = null
var is_moving_to_player: bool = false

@onready var sprite = $Sprite2D

func _ready() -> void:
    # Set up the timer to automatically remove the pickup after lifetime seconds
    var timer = get_tree().create_timer(lifetime)
    timer.timeout.connect(_on_timer_timeout)
    
    # Connect the area_entered signal
    area_entered.connect(_on_area_entered)
    
    # Create a simple visual representation
    var circle = CircleShape2D.new()
    circle.radius = 15.0
    $CollisionShape2D.shape = circle
    
    # Start pulsing animation
    $AnimationPlayer.play("pulse")

func _physics_process(delta: float) -> void:
    if not GameManager.player:
        return
        
    var player = GameManager.player
    var distance_to_player = global_position.distance_to(player.global_position)
    
    # If player is close enough, start moving towards them
    if distance_to_player < attract_distance:
        is_moving_to_player = true
        target = player
    
    # Move towards the player if we have a target
    if is_moving_to_player and target:
        var direction = (target.global_position - global_position).normalized()
        position += direction * move_speed * delta

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_hitbox"):
        var player = area.get_parent()
        if player.has_method("heal"):
            player.heal(heal_amount)
            # Create heal effect (if you have one)
            if ResourceLoader.exists("res://Scenes/HealEffect.tscn"):
                var heal_effect = load("res://Scenes/HealEffect.tscn").instantiate()
                player.add_child(heal_effect)
                heal_effect.global_position = player.global_position
        queue_free()

func _on_timer_timeout() -> void:
    # Create a tween for fade out effect
    var tween = create_tween()
    tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.5)
    tween.tween_callback(queue_free)
