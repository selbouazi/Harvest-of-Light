class_name LightUtil
## Luces 2D de la identidad visual. Se mezclan en modo "add" sobre una escena ya oscura:
## la oscuridad es de paleta (ambiente), nunca tapa la zona de combate (D14).

static var _cache: Dictionary = {}


static func radial_texture(size: int = 256) -> GradientTexture2D:
	if _cache.has(size):
		return _cache[size]
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	_cache[size] = t
	return t


static func make_light(radius_px: float, color: Color, energy: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = radial_texture()
	l.texture_scale = radius_px * 2.0 / 256.0
	l.color = color
	l.energy = energy
	l.blend_mode = Light2D.BLEND_MODE_ADD
	return l
