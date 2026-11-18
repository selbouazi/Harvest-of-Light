class_name Player
extends CharacterBody2D
## Moveset base (K2): caminar, salto, ataque en 4 direcciones, esquiva corta.
## Movimiento e hitbox CONSTANTES para todas las casas: ninguna stat los modifica.
## Referencia de combate: compromiso (cada ataque tiene arranque y recuperación).

signal died

enum State { NORMAL, ATTACK, DODGE, HURT, HEAL, DEAD }

# --- Movimiento (constantes de diseño de niveles: no tocar sin revisar salas) ---
const RUN_SPEED := 130.0
const GROUND_ACCEL := 1500.0
const AIR_ACCEL := 1000.0
const GRAVITY := 980.0
const FALL_GRAVITY_MULT := 1.6
const MAX_FALL_SPEED := 420.0
const JUMP_VELOCITY := -330.0          # salto completo ≈ 3,5 tiles de 16 px
const JUMP_CUT_MULT := 0.45            # soltar el botón corta el salto
const COYOTE_S := 0.10
const JUMP_BUFFER_S := 0.12

# --- Esquiva de combate (NO es el Dash de exploración) ---
const DODGE_SPEED := 250.0
const DODGE_S := 0.22
const DODGE_IFRAMES_S := 0.18
const DODGE_COOLDOWN_S := 0.40

# --- Ataque (la velocidad la definirá el arma) ---
const ATTACK_STARTUP_S := 0.06
const ATTACK_ACTIVE_S := 0.10
const ATTACK_RECOVERY_S := 0.20
const ATTACK_REACH := 22.0
const POGO_VELOCITY := -280.0

# --- Daño recibido ---
const HURT_S := 0.25
const HURT_IFRAMES_S := 0.9
const HURT_KNOCKBACK := Vector2(160.0, -180.0)

const BODY_SIZE := Vector2(12, 28)

@export var stats: StatsConfig = preload("res://data/stats/default_stats.tres")

var state: State = State.NORMAL
var facing := 1
var max_hp: int
var hp: int
var light := 0.0
var _light_budget := 0.0

var _state_t := 0.0
var _coyote_t := 0.0
var _jump_buffer_t := 0.0
var _iframes_t := 0.0
var _dodge_cd_t := 0.0
var _attack_dir := Vector2.RIGHT
var _attack_hit: Array[Node] = []

@onready var _attack_area: Area2D = $AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _slash: Sprite2D = $AttackHitbox/Slash


func _ready() -> void:
	max_hp = stats.max_hp_at(GameState.level)
	hp = max_hp
	_light_budget = stats.light_gain_cap_per_s
	_attack_shape.disabled = true
	_slash.visible = false
	var lantern := LightUtil.make_light(100.0, Color(1.0, 0.8, 0.45), 0.85)
	lantern.position = Vector2(0, -16)
	add_child(lantern)
	EventBus.light_changed.emit(light, stats.light_max)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	match state:
		State.NORMAL: _state_normal(delta)
		State.ATTACK: _state_attack(delta)
		State.DODGE: _state_dodge(delta)
		State.HURT: _state_hurt(delta)
		State.HEAL: _state_heal(delta)
		State.DEAD: _apply_gravity(delta)
	move_and_slide()
	if state != State.DEAD:
		_check_contact_damage()
	_update_visuals()


# ---------------------------------------------------------------- estados

func _state_normal(delta: float) -> void:
	_run(delta, Input.get_axis("move_left", "move_right"))
	_apply_gravity(delta)
	_handle_jump()
	if Input.is_action_just_pressed("dodge") and _dodge_cd_t <= 0.0:
		_start_dodge()
	elif Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("heal") and is_on_floor() and light >= stats.heal_cost and hp < max_hp:
		_change_state(State.HEAL)


func _state_attack(delta: float) -> void:
	# Compromiso: en el suelo frenas; en el aire conservas parte del control.
	var axis := Input.get_axis("move_left", "move_right") if not is_on_floor() else 0.0
	_run(delta, axis * 0.6)
	_apply_gravity(delta)
	var active_from := ATTACK_STARTUP_S
	var active_to := ATTACK_STARTUP_S + ATTACK_ACTIVE_S
	_attack_shape.disabled = not (_state_t >= active_from and _state_t < active_to)
	if not _attack_shape.disabled:
		_resolve_attack_hits()
	if _state_t >= active_to + ATTACK_RECOVERY_S:
		_attack_shape.disabled = true
		_change_state(State.NORMAL)


func _state_dodge(_delta: float) -> void:
	velocity.x = DODGE_SPEED * facing
	velocity.y = 0.0
	if _state_t >= DODGE_S:
		velocity.x = RUN_SPEED * facing * 0.5
		_change_state(State.NORMAL)


func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCEL * 0.3 * delta)
	if _state_t >= HURT_S:
		_change_state(State.NORMAL)


## Curación canalizada: soltar el botón, moverse o recibir daño la cancela sin gastar luz.
func _state_heal(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCEL * delta)
	_apply_gravity(delta)
	if not Input.is_action_pressed("heal") or absf(Input.get_axis("move_left", "move_right")) > 0.5:
		_change_state(State.NORMAL)
		return
	if _state_t >= stats.heal_channel_s:
		light -= stats.heal_cost
		var amount := mini(stats.heal_amount(max_hp), max_hp - hp)
		hp += amount
		EventBus.player_healed.emit(amount)
		EventBus.light_changed.emit(light, stats.light_max)
		_change_state(State.NORMAL)


# ---------------------------------------------------------------- acciones

func _run(delta: float, axis: float) -> void:
	if absf(axis) > 0.2 and state == State.NORMAL:
		facing = 1 if axis > 0.0 else -1
	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, axis * RUN_SPEED, accel * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_t = JUMP_BUFFER_S
	if _jump_buffer_t > 0.0 and _coyote_t > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_t = 0.0
		_coyote_t = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULT


func _start_attack() -> void:
	if Input.is_action_pressed("move_up"):
		_attack_dir = Vector2.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		_attack_dir = Vector2.DOWN
	else:
		_attack_dir = Vector2(facing, 0)
	_attack_area.position = _attack_dir * ATTACK_REACH + Vector2(0, -BODY_SIZE.y * 0.5)
	_attack_area.rotation = _attack_dir.angle()
	_attack_hit.clear()
	_change_state(State.ATTACK)


func _start_dodge() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.2:
		facing = 1 if axis > 0.0 else -1
	_iframes_t = maxf(_iframes_t, DODGE_IFRAMES_S)
	_dodge_cd_t = DODGE_COOLDOWN_S
	_change_state(State.DODGE)


func _resolve_attack_hits() -> void:
	for body in _attack_area.get_overlapping_bodies():
		if body in _attack_hit or not body.has_method("take_hit"):
			continue
		_attack_hit.append(body)
		var dmg := roundi(stats.damage_at(GameState.level))
		body.take_hit(dmg, DamageTypes.Type.PHYSICAL, _attack_dir)
		gain_light(stats.light_per_hit)
		if _attack_dir == Vector2.DOWN:
			velocity.y = POGO_VELOCITY
		elif _attack_dir.x != 0.0 and is_on_floor():
			velocity.x = -_attack_dir.x * 60.0   # pequeño retroceso propio
		Hitstop.request(0.05)


## Ganancia de luz con tope por segundo (anti-sustain infinito, I1).
func gain_light(amount: float) -> void:
	var granted := minf(amount, _light_budget)
	_light_budget -= granted
	light = minf(light + granted, stats.light_max)
	EventBus.light_changed.emit(light, stats.light_max)


# ---------------------------------------------------------------- daño

func _check_contact_damage() -> void:
	if _iframes_t > 0.0:
		return
	for body in _hurtbox.get_overlapping_bodies():
		if body.has_method("get_contact_damage"):
			take_damage(body.get_contact_damage(), signf(global_position.x - body.global_position.x))
			return
	for area in _hurtbox.get_overlapping_areas():
		if area.has_method("get_contact_damage"):
			take_damage(area.get_contact_damage(), signf(global_position.x - area.global_position.x))
			return


func take_damage(amount: int, from_dir: float = 0.0) -> void:
	if _iframes_t > 0.0 or state == State.DEAD:
		return
	hp = maxi(0, hp - amount)
	EventBus.player_damaged.emit(amount, hp)
	_attack_shape.disabled = true
	if hp == 0:
		_die()
		return
	var dir := from_dir if from_dir != 0.0 else float(-facing)
	velocity = Vector2(HURT_KNOCKBACK.x * dir, HURT_KNOCKBACK.y)
	_iframes_t = HURT_IFRAMES_S
	Hitstop.request(0.08)
	_change_state(State.HURT)


func _die() -> void:
	_change_state(State.DEAD)
	velocity = Vector2.ZERO
	EventBus.player_died.emit()
	died.emit()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	max_hp = stats.max_hp_at(GameState.level)
	hp = max_hp
	light = 0.0
	_iframes_t = 1.0
	EventBus.light_changed.emit(light, stats.light_max)
	_change_state(State.NORMAL)


func is_invulnerable() -> bool:
	return _iframes_t > 0.0


# ---------------------------------------------------------------- utilidades

func _change_state(s: State) -> void:
	state = s
	_state_t = 0.0


func _tick_timers(delta: float) -> void:
	_state_t += delta
	_iframes_t = maxf(0.0, _iframes_t - delta)
	_dodge_cd_t = maxf(0.0, _dodge_cd_t - delta)
	_jump_buffer_t = maxf(0.0, _jump_buffer_t - delta)
	_coyote_t = COYOTE_S if is_on_floor() else maxf(0.0, _coyote_t - delta)
	_light_budget = minf(_light_budget + stats.light_gain_cap_per_s * delta, stats.light_gain_cap_per_s)


## Elige animación y efectos según el estado. El arte sale de tools/art/gen_art.py.
func _update_visuals() -> void:
	_sprite.flip_h = facing < 0
	_sprite.position.x = 1.5 * facing
	var anim := &"idle"
	match state:
		State.NORMAL:
			if not is_on_floor():
				anim = &"jump" if velocity.y < 0.0 else &"fall"
			elif absf(velocity.x) > 10.0:
				anim = &"run"
		State.ATTACK: anim = &"attack"
		State.DODGE: anim = &"dodge"
		State.HURT: anim = &"hurt"
		State.HEAL: anim = &"heal"
		State.DEAD: anim = &"dead"
	if _sprite.animation != anim:
		_sprite.play(anim)
	if state == State.ATTACK:
		# Fotogramas ligados a las fases del golpe, no a un reloj aparte.
		var f := 0 if _state_t < ATTACK_STARTUP_S else (1 if _state_t < ATTACK_STARTUP_S + ATTACK_ACTIVE_S else 2)
		_sprite.frame = f
		_slash.visible = f >= 1 and _state_t < ATTACK_STARTUP_S + ATTACK_ACTIVE_S + 0.08
		_slash.frame = clampi(int((_state_t - ATTACK_STARTUP_S) / 0.06), 0, 2)
	else:
		_slash.visible = false
	var a := 1.0
	if _iframes_t > 0.0 and state != State.DODGE and int(_iframes_t * 20.0) % 2 == 0:
		a = 0.35
	_sprite.modulate = Color(1.6, 1.2, 1.2, a) if state == State.HURT else Color(1, 1, 1, a)
