class_name HollowedBearer
extends CharacterBody2D
## "Portador vaciado": enemigo común de prueba. Patrulla, telegrafía y embiste.
## Sirve para validar el ciclo telegrafía → activo → recuperación → castigo.

enum State { PATROL, TELEGRAPH, LUNGE, RECOVER, STAGGER, DEAD }

const SIZE := Vector2(16, 22)
const GRAVITY := 980.0

@export var enemy_id: StringName = &"hollowed_bearer"
@export var max_hp: int = 36
@export var contact_damage: int = 12
@export var lunge_damage: int = 20
@export var patrol_speed: float = 35.0
@export var aggro_range: float = 90.0
@export var lunge_speed: float = 230.0
@export var attack: AttackData
@export var resistances: Dictionary = {0: 1.0, 1: 1.3, 2: 0.7}
@export var xp: int = 15
@export var brasas: int = 10

var hp: int
var state: State = State.PATROL
var facing := -1
var _t := 0.0
var _flash_t := 0.0

@onready var _edge_ray: RayCast2D = $EdgeRay
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hp = max_hp
	if attack == null:
		attack = AttackData.new()
		attack.telegraph_s = 0.55
		attack.active_s = 0.30
		attack.recovery_s = 0.70
		attack.damage = lunge_damage


func _physics_process(delta: float) -> void:
	_t += delta
	_flash_t = maxf(0.0, _flash_t - delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	match state:
		State.PATROL: _patrol()
		State.TELEGRAPH:
			velocity.x = 0.0
			if _t >= attack.effective_telegraph():
				_set_state(State.LUNGE)
		State.LUNGE:
			velocity.x = lunge_speed * facing
			if _t >= attack.active_s or is_on_wall():
				_set_state(State.RECOVER)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _t >= attack.recovery_s:
				_set_state(State.PATROL)
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t >= 0.25:
				_set_state(State.PATROL)
		State.DEAD:
			return
	move_and_slide()
	_update_visuals()
	queue_redraw()


func _patrol() -> void:
	_edge_ray.position.x = facing * (SIZE.x * 0.5 + 2.0)
	if is_on_wall() or (is_on_floor() and not _edge_ray.is_colliding()):
		facing = -facing
	velocity.x = patrol_speed * facing
	var player := _find_player()
	if player and absf(player.global_position.y - global_position.y) < 30.0:
		var dx := player.global_position.x - global_position.x
		if absf(dx) < aggro_range:
			facing = 1 if dx > 0.0 else -1
			_set_state(State.TELEGRAPH)


func get_contact_damage() -> int:
	if state == State.DEAD:
		return 0
	return lunge_damage if state == State.LUNGE else contact_damage


func take_hit(amount: int, type: DamageTypes.Type, dir: Vector2) -> void:
	if state == State.DEAD:
		return
	var mult: float = resistances.get(int(type), 1.0)
	var dmg := CombatMath.final_damage(amount, mult, 0.0, 1.0, 0.0)
	hp -= dmg
	_flash_t = 0.08
	if hp <= 0:
		_die()
		return
	# Golpear durante la telegrafía NO la interrumpe (compromiso del enemigo); en patrulla sí aturde.
	if state == State.PATROL or state == State.RECOVER:
		velocity.x = signf(dir.x) * 120.0 if dir.x != 0.0 else 0.0
		_set_state(State.STAGGER)


func _die() -> void:
	_set_state(State.DEAD)
	var times := int(GameState.get_flag(StringName("kills/%s" % enemy_id), 0))
	GameState.set_flag(StringName("kills/%s" % enemy_id), times + 1)
	var gained_xp := CombatMath.xp_with_decay(xp, times)
	GameState.xp += gained_xp
	GameState.add_brasas(brasas)
	EventBus.enemy_killed.emit(enemy_id, gained_xp, brasas)
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _set_state(s: State) -> void:
	state = s
	_t = 0.0


func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func _update_visuals() -> void:
	_sprite.flip_h = facing < 0
	var anim: StringName = {
		State.PATROL: &"walk", State.TELEGRAPH: &"telegraph", State.LUNGE: &"lunge",
		State.RECOVER: &"recover", State.STAGGER: &"stagger", State.DEAD: &"stagger",
	}[state]
	if _sprite.animation != anim:
		_sprite.play(anim)
	if _flash_t > 0.0:
		_sprite.modulate = Color(3, 3, 3)
	elif state == State.TELEGRAPH:
		# Contraste fijo, independiente de la luz de la sala (D14).
		_sprite.modulate = Color(1.5, 1.2, 0.9) if int(_t * 12.0) % 2 == 0 else Color(1, 1, 1)
	else:
		_sprite.modulate = Color(1, 1, 1)


## Barra de vida (encima del sprite: el sprite tiene show_behind_parent).
func _draw() -> void:
	if state == State.DEAD or hp >= max_hp:
		return
	var w := 18.0 * float(maxi(hp, 0)) / float(max_hp)
	draw_rect(Rect2(Vector2(-9, -34), Vector2(18, 2)), Color(0.1, 0.05, 0.08))
	draw_rect(Rect2(Vector2(-9, -34), Vector2(w, 2)), Color(0.9, 0.25, 0.2))
