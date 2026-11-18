class_name BossTemplate
extends Resource
## Jefes y minijefes como datos (K6). Solo las mecánicas firma llevan script propio.

@export var id: StringName
@export var display_name: String
@export var max_hp: int = 400
@export var contact_damage: int = 15
## Multiplicadores por DamageTypes.Type, siempre en [0.5, 1.5].
@export var resistances: Dictionary = {0: 1.0, 1: 1.0, 2: 1.0}
@export var phases: Array[BossPhase] = []
@export var xp: int = 100
@export var brasas: int = 80
## Script opcional con la mecánica firma.
@export var signature_script: Script
