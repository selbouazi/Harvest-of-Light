# Hitos y criterios de salida

Regla: **no se pasa de hito sin cumplir su criterio de salida.**
Señal de alarma: si el repo tiene más documentos que escenas jugables, se está perdiendo.

## 0 · Preproducción (4–6 semanas)
- [x] Repo en Git, CLAUDE.md con versión fijada, tests automáticos, CI.
- [x] Arena de pruebas con moveset base y un enemigo.
- [x] Resolver horas/semana (D18), arte y música (D19, D20) y Magia (D21).
- [x] Prueba de arte: héroe, enemigo, fondo de 3 capas y luces, generados por script (D22, D23).
- [ ] Probar Light2D y el rendimiento en el hardware mínimo.
- [ ] Especificar fotogramas del moveset (arranque/activo/recuperación) y tabla de daño.
- [ ] Matriz de puertas y habilidades + grafo del mundo de las 3 regiones (A6).
- [ ] Documento de la R1 (salas con ID, Sellos, NPC, objetos).
- [ ] Activar Git LFS antes del primer arte pesado (`git lfs track "*.png" "*.ogg" "*.wav"`).

## 1 · Prototipo gris (~150–250 h) — puerta de decisión del combate
Arte provisional (rectángulos). Una arena.
- [x] Movimiento, salto con coyote/buffer, cámara.
- [x] Ataque 4 direcciones, pogo, esquiva con i-frames, daño recibido con knockback.
- [x] Enemigo con telegrafía → embestida → recuperación castigable.
- [x] Luz y curación canalizada (con tope anti-sustain).
- [ ] 2 enemigos comunes más con patrones distintos.
- [ ] 1 minijefe en datos (`BossTemplate` + `AttackData`).
- [ ] Ajuste de feel: hitstop, screenshake opcional, partículas mínimas.
- **Salida:** 2–3 personas lo prueban sin explicación; se siente bien varios días seguidos.
  Si no, se rehace el combate **antes** de pagar arte final.

## 2 · Vertical Slice (~20 min, calidad final)
Checkpoint, mapa por ID, guardado con flags, tienda, sombra, 1 jefe con fases, arte y audio finales.
- **Salida:** una persona externa lo termina sin ayuda.

## 3 · Primer Bioma (R1 completa)
3–4 Sellos, jefe con habilidad de exploración, 12–15 objetos, ~6 NPC, 1 mercader.
- **Salida:** 3–5 testers la completan sin bugs bloqueantes. Medir horas reales por sala/jefe/NPC.
  Si el coste real > 2× lo estimado → recortar más antes de seguir.

## 4 · Alpha → 5 · Beta → 6 · Release
Ver la evaluación unificada, sección 8.
