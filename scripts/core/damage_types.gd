class_name DamageTypes
## 3 tipos de daño (decisión I4). Fuego y Rayo serán propiedades de arma, no tipos.

enum Type { PHYSICAL, LIGHT, SHADOW }

const RESIST_MIN := 0.5   # nunca 0: sin inmunidades, sin softlocks
const RESIST_MAX := 1.5
