extends Node
## Bus de eventos global. Los sistemas se comunican por señales, no por referencias directas.

signal player_damaged(amount: int, hp_left: int)
signal player_died
signal player_healed(amount: int)
signal light_changed(current: float, maximum: float)
signal enemy_killed(enemy_id: StringName, xp: int, brasas: int)
signal boss_defeated(boss_id: StringName)
signal checkpoint_reached(room_id: StringName, checkpoint_id: StringName)
signal room_entered(room_id: StringName)
signal flag_set(flag_id: StringName, value: Variant)
signal brasas_changed(amount: int)
