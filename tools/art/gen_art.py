#!/usr/bin/env python3
"""Generador del arte provisional-final del prototipo (decisión D19).

Todo el pixel art se dibuja por código con una paleta fija, así que se puede
rehacer o retocar cambiando parámetros y volviendo a ejecutar:

    python3 tools/art/gen_art.py

Escribe PNG en assets/art/ y SpriteFrames .tres en assets/art/frames/.
Requisitos: Pillow y numpy.
"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "art"
FRAMES_OUT = OUT / "frames"

# ----------------------------------------------------------------- paleta
# Índice 0 = transparente. Mantener la paleta corta: es lo que da coherencia.
PALETTE = {
    1: "0d0b14",   # contorno
    2: "2b3346", 3: "3f4c63", 4: "5b6c84",           # capa del Errante
    6: "a8642a", 7: "e0a040", 8: "ffe08a", 9: "fff8e0",  # luz / bufanda
    10: "6d7385", 11: "c9cfdc",                      # metal
    12: "241d26",                                    # botas
    13: "3a3448", 14: "564d68", 15: "7b7193",        # carne del vaciado
    16: "5a4330", 17: "806040",                      # cesto
    18: "ff8a2a", 19: "ffd23f",                      # ojo / telegrafía
    20: "0b0d1c", 21: "161a33", 22: "2a2546",        # cielo
    23: "1d2038", 24: "141629", 25: "0c0d18",        # siluetas lejos → cerca
    26: "23263a", 27: "33384f", 28: "4a5170", 29: "8a7a3a",  # piedra
}
RGBA = np.zeros((256, 4), dtype=np.uint8)
for i, h in PALETTE.items():
    RGBA[i] = [int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255]


class Canvas:
    """Lienzo de índices de paleta con utilidades de PIL."""

    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.img = Image.new("L", (w, h), 0)
        self.d = ImageDraw.Draw(self.img)

    def rect(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=c)

    def poly(self, pts, c):
        self.d.polygon([tuple(map(round, p)) for p in pts], fill=c)

    def ellipse(self, x0, y0, x1, y1, c):
        self.d.ellipse([x0, y0, x1, y1], fill=c)

    def line(self, p0, p1, c, width=1):
        self.d.line([tuple(map(round, p0)), tuple(map(round, p1))], fill=c, width=width)

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((int(x), int(y)), c)

    def array(self) -> np.ndarray:
        return np.array(self.img, dtype=np.uint8)


def outline(a: np.ndarray, color: int = 1) -> np.ndarray:
    """Contorno de 1 px (vecindad 4) alrededor de lo opaco."""
    solid = a > 0
    grow = np.zeros_like(solid)
    grow[1:, :] |= solid[:-1, :]
    grow[:-1, :] |= solid[1:, :]
    grow[:, 1:] |= solid[:, :-1]
    grow[:, :-1] |= solid[:, 1:]
    out = a.copy()
    out[grow & ~solid] = color
    return out


def to_image(a: np.ndarray) -> Image.Image:
    return Image.fromarray(RGBA[a], "RGBA")


def sheet(rows: list[list[np.ndarray]], fw: int, fh: int) -> Image.Image:
    cols = max(len(r) for r in rows)
    img = Image.new("RGBA", (cols * fw, len(rows) * fh), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, fr in enumerate(row):
            img.paste(to_image(fr), (x * fw, y * fh))
    return img


# ----------------------------------------------------------------- Errante (protagonista)
HW, HH = 28, 32


def hero(bob=0, crouch=0, legs=((-1, 0), (1, 0)), sway=0, hem_lift=0, sword="down",
         lean=0, tail=0, glow=False, eye=9) -> np.ndarray:
    cv = Canvas(HW, HH)
    cx = 12
    t = bob + crouch
    sh = 12 + t                      # hombros
    hem = min(27, 26 + t - hem_lift)  # bajo de la capa
    leg_h = 6 - min(crouch, 3)

    # piernas (la de atrás primero)
    for i, (dx, lift) in enumerate(legs):
        x = cx - 3 + dx if i == 0 else cx + 1 + dx
        foot = 31 - lift
        cv.rect(x, foot - leg_h + 1, x + 2, foot, 12)
        cv.px(x + (2 if i == 1 else 0), foot, 1 if i == 0 else 12)

    # cola de la bufanda (detrás del cuerpo)
    tx = cx - 3 + lean
    cv.poly([(tx, sh - 1), (tx - 5 - tail, sh + 1 + tail // 2), (tx - 6 - tail, sh + 3),
             (tx - 1, sh + 1)], 6)
    cv.line((tx - 1, sh), (tx - 5 - tail, sh + 2), 7)

    # capa
    l, r = cx - 3 + lean, cx + 4 + lean
    cv.poly([(l, sh), (r, sh), (cx + 6 + lean + sway // 2, hem), (cx - 6 + sway, hem)], 3)
    cv.poly([(l, sh), (cx + lean - 1, sh), (cx - 2 + sway, hem), (cx - 6 + sway, hem)], 2)
    cv.line((r, sh + 1), (cx + 6 + lean + sway // 2, hem - 1), 4)
    for x in range(cx - 5 + sway, cx + 6 + lean, 3):   # flecos del bajo
        cv.px(x, hem + 1, 2)

    # capucha y rostro en sombra
    hx = cx + lean
    cv.poly([(hx - 4, 5 + t), (hx - 8, 10 + t), (hx - 3, 11 + t)], 2)   # pico de la capucha
    cv.ellipse(hx - 4, 3 + t, hx + 4, 12 + t, 3)
    cv.ellipse(hx - 4, 4 + t, hx, 12 + t, 2)
    cv.line((hx - 2, 3 + t), (hx + 2, 3 + t), 4)
    cv.ellipse(hx, 6 + t, hx + 4, 11 + t, 1)
    cv.px(hx + 3, 8 + t, eye)
    cv.px(hx + 1, 8 + t, 8 if eye == 9 else eye)

    # bufanda (la luz del Errante)
    cv.rect(hx - 3, 11 + t, hx + 4, 12 + t, 9 if glow else 7)
    cv.line((hx - 2, 11 + t), (hx + 3, 11 + t), 9 if glow else 8)

    # brazo y espada
    s = (hx + 2, sh + 2)
    if sword == "down":
        hand, tip = (hx + 4, sh + 6), (hx + 8, sh + 14)
    elif sword == "up":         # preparación: espada atrás y arriba
        hand, tip = (hx + 1, sh - 2), (hx - 6, sh - 9)
    elif sword == "forward":    # golpe
        hand, tip = (hx + 6, sh + 3), (hx + 13, sh + 3)
    elif sword == "recover":
        hand, tip = (hx + 5, sh + 6), (hx + 11, sh + 11)
    else:                       # "none"
        hand, tip = (hx + 3, sh + 6), None
    cv.line(s, hand, 4, 2)
    if tip:
        cv.line(hand, tip, 11)
        cv.px(*hand, 6)
    if glow:
        for (gx, gy) in [(hx - 6, sh + 2), (hx + 7, sh + 1), (hx - 1, sh - 10), (hx + 5, sh - 7)]:
            cv.px(gx, gy + bob, 8)

    return outline(cv.array())


def hero_frames():
    idle = [hero(bob=b, sway=s) for b, s in [(0, 0), (0, 1), (1, 1), (1, 0)]]
    run = []
    for i in range(6):
        ph = i / 6 * 2 * math.pi
        front = (round(2.5 * math.sin(ph)), max(0, round(2 * math.cos(ph))))
        back = (round(-2.5 * math.sin(ph)), max(0, round(-2 * math.cos(ph))))
        run.append(hero(bob=1 if abs(math.sin(ph)) < 0.6 else 0, legs=(back, front),
                        sway=-2, lean=1, tail=2 + i % 2))
    jump = [hero(legs=((-2, 3), (2, 2)), hem_lift=3, sway=-1, tail=1)]
    fall = [hero(legs=((-1, 1), (1, 2)), hem_lift=5 - i, sway=-3, tail=3) for i in range(2)]
    attack = [hero(sword="up", lean=-1, legs=((-2, 0), (1, 0))),
              hero(sword="forward", lean=2, legs=((-3, 0), (3, 0)), sway=-2, tail=2),
              hero(sword="recover", lean=1, legs=((-2, 0), (2, 0)), sway=-1)]
    dodge = [hero(crouch=4, lean=2, sway=-4, legs=((-3, 0), (3, 0)), tail=4, sword="none"),
             hero(crouch=3, lean=1, sway=-3, legs=((-2, 0), (2, 0)), tail=3, sword="none")]
    hurt = [hero(lean=-2, sway=2, legs=((-2, 0), (1, 1)), sword="recover", eye=8)]
    heal = [hero(glow=True, sword="none", sway=0), hero(glow=True, bob=1, sword="none", sway=1)]
    dead = [dead_hero()]
    return {"idle": (idle, 6, True), "run": (run, 12, True), "jump": (jump, 1, False),
            "fall": (fall, 8, True), "attack": (attack, 0, False), "dodge": (dodge, 12, False),
            "hurt": (hurt, 1, False), "heal": (heal, 6, True), "dead": (dead, 1, False)}


def dead_hero() -> np.ndarray:
    cv = Canvas(HW, HH)
    cv.ellipse(2, 25, 20, 31, 3)
    cv.ellipse(2, 27, 12, 31, 2)
    cv.ellipse(15, 24, 22, 30, 3)
    cv.rect(8, 28, 14, 29, 6)
    cv.line((0, 31), (9, 30), 11)
    return outline(cv.array())


# ----------------------------------------------------------------- Portador vaciado (enemigo)
EW, EH = 32, 32


def bearer(dx=0, dy=0, hand=(24, 26), hand2=None, legs=(0, 0), eye=18, eye_glow=False,
           head_dy=0) -> np.ndarray:
    """Figura humana encorvada con un cesto vacío a la espalda y máscara pálida."""
    cv = Canvas(EW, EH)
    # piernas flexionadas (cadera → rodilla → pie)
    for i, off in enumerate(legs):
        hx = 12 + dx + i * 4
        knee = (hx + 2 + off, 25 + max(dy, 0) // 2)
        foot = (hx + off - (1 if i == 0 else -1), 31)
        cv.line((hx, 20 + dy), knee, 13, 2)
        cv.line(knee, foot, 13, 2)
    # cesto vacío (lo que le cosecharon)
    kx, ky = 4 + dx, 2 + dy
    cv.rect(kx, ky + 1, kx + 9, ky + 11, 16)
    for yy in range(ky + 3, ky + 11, 3):
        cv.line((kx, yy), (kx + 9, yy), 17)
    for xx in range(kx + 2, kx + 9, 3):
        cv.line((xx, ky + 1), (xx, ky + 11), 17)
    cv.rect(kx + 1, ky, kx + 8, ky + 2, 1)
    # torso inclinado hacia delante
    cv.poly([(10 + dx, 21 + dy), (18 + dx, 21 + dy), (23 + dx, 12 + dy), (20 + dx, 8 + dy), (12 + dx, 9 + dy)], 14)
    cv.poly([(10 + dx, 21 + dy), (14 + dx, 21 + dy), (15 + dx, 10 + dy), (12 + dx, 9 + dy)], 13)
    cv.line((13 + dx, 9 + dy), (20 + dx, 8 + dy), 15)
    cv.line((kx + 8, ky + 5), (17 + dx, 12 + dy), 16)  # correa
    # cuello y máscara pálida
    hy = 9 + dy + head_dy
    cv.line((21 + dx, 12 + dy), (23 + dx, hy + 3), 13, 2)
    cv.ellipse(22 + dx, hy, 29 + dx, hy + 7, 15)
    cv.ellipse(22 + dx, hy + 4, 28 + dx, hy + 7, 14)
    cv.rect(25 + dx, hy + 2, 28 + dx, hy + 3, 1)
    cv.rect(26 + dx, hy + 2, 27 + dx, hy + 3, eye)
    if eye_glow:
        cv.px(29 + dx, hy + 2, 19)
        cv.px(24 + dx, hy + 3, 19)
        cv.px(27 + dx, hy, 8)
    a = outline(cv.array())
    # brazo(s) con contorno propio para que se lea sobre el torso
    arm = Canvas(EW, EH)
    sh = (20 + dx, 12 + dy)
    for h in [hand] + ([hand2] if hand2 else []):
        arm.line(sh, h, 15, 2)
        arm.px(h[0] + 1, h[1], 11)
    b = arm.array()
    ring = outline(b) == 1
    a[ring] = 1
    a[b > 0] = b[b > 0]
    return a


def bearer_frames():
    walk = [bearer(hand=(23 + d, 26), legs=(l0, l1), dy=b)
            for d, l0, l1, b in [(0, -1, 1, 0), (1, 0, 0, 1), (2, 1, -1, 0), (1, 0, 0, 1)]]
    telegraph = [bearer(dy=-2, head_dy=-1, hand=(18, 1), hand2=(23, 2), eye=19, eye_glow=True),
                 bearer(dy=-3, head_dy=-1, hand=(17, 0), hand2=(22, 1), eye=9, eye_glow=True)]
    lunge = [bearer(dx=2, dy=1, hand=(31, 14), hand2=(30, 17), legs=(-3, 3), eye=19)]
    recover = [bearer(dy=2, head_dy=2, hand=(26, 30), eye=16)]
    stagger = [bearer(dx=-2, head_dy=-1, hand=(19, 22), eye=9)]
    return {"walk": (walk, 6, True), "telegraph": (telegraph, 10, True),
            "lunge": (lunge, 1, False), "recover": (recover, 1, False),
            "stagger": (stagger, 1, False)}


# ----------------------------------------------------------------- tajo
def slash_frames() -> list[np.ndarray]:
    frames = []
    for i in range(3):
        cv = Canvas(32, 24)
        outer = [(2, 0, 30, 23), (0, 0, 31, 23), (4, 2, 31, 21)][i]
        inner = [(-6, 3, 24, 20), (-8, 2, 25, 21), (-4, 4, 25, 19)][i]
        cv.ellipse(*outer, [9, 8, 7][i])
        cv.ellipse(outer[0] + 3, outer[1] + 2, outer[2] - 1, outer[3] - 2, [8, 7, 6][i])
        cv.ellipse(*inner, 0)
        a = cv.array()
        if i == 2:  # se deshace con trama
            mask = (np.indices(a.shape).sum(axis=0) % 2) == 0
            a[mask] = 0
        frames.append(a)
    return frames


# ----------------------------------------------------------------- tiles y farol
def tiles() -> Image.Image:
    rng = random.Random(7)
    cv = Canvas(32, 16)
    # 0: superficie
    cv.rect(0, 0, 15, 15, 27)
    cv.rect(0, 0, 15, 1, 28)
    for x in range(0, 16):
        if rng.random() < 0.35:
            cv.px(x, 2, 29)
    for x in (0, 8):
        cv.line((x, 6), (x, 10), 26)
    cv.line((0, 5), (15, 5), 26)
    cv.line((0, 11), (15, 11), 26)
    cv.line((4, 12), (4, 15), 26)
    cv.line((12, 12), (12, 15), 26)
    # 1: relleno
    cv.rect(16, 0, 31, 15, 26)
    for y in (0, 8):
        cv.line((16, y), (31, y), 24)
    for x, y0 in [(20, 1), (28, 1), (16, 9), (24, 9)]:
        cv.line((x, y0), (x, y0 + 6), 24)
    for _ in range(10):
        cv.px(rng.randrange(16, 32), rng.randrange(0, 16), 27)
    return to_image(cv.array())


def lantern_post() -> Image.Image:
    frames = []
    for lit in (False, True):
        cv = Canvas(16, 32)
        cv.rect(7, 10, 8, 31, 27)
        cv.line((6, 31), (9, 31), 26)
        cv.rect(4, 2, 11, 10, 10)
        cv.rect(5, 3, 10, 9, 8 if lit else 1)
        if lit:
            cv.rect(6, 4, 9, 7, 9)
        cv.line((4, 1), (11, 1), 11)
        cv.px(7, 0, 11)
        cv.px(8, 0, 11)
        frames.append(outline(cv.array()))
    return sheet([frames], 16, 32)


# ----------------------------------------------------------------- fondos (640×360, en bucle horizontal)
W, H = 640, 360
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def ridge(seed: int, base: float, amps: list[tuple[int, float]]) -> np.ndarray:
    """Perfil de altura en bucle: los periodos dividen 640, así encaja al repetir."""
    rng = random.Random(seed)
    x = np.arange(W)
    y = np.full(W, float(base))
    for period_div, amp in amps:
        y += amp * np.sin(2 * np.pi * x * period_div / W + rng.random() * 6.28)
    return y


def sky() -> Image.Image:
    a = np.zeros((H, W), dtype=np.uint8)
    yy = np.arange(H)[:, None] / H
    t = np.clip(yy * 2.2, 0, 2) + BAYER[np.arange(H)[:, None] % 4, np.arange(W)[None, :] % 4] * 0.9 - 0.45
    a[:] = np.where(t < 0.7, 20, np.where(t < 1.5, 21, 22))
    rng = random.Random(3)
    for _ in range(140):
        x, y = rng.randrange(W), rng.randrange(int(H * 0.55))
        a[y, x] = rng.choice([11, 10, 10, 9])
    # luna menguante
    cv = Image.fromarray(a, "L")
    d = ImageDraw.Draw(cv)
    d.ellipse([470, 40, 506, 76], fill=11)
    d.ellipse([480, 34, 516, 70], fill=20)
    # el Faro lejano: la única luz que queda en el horizonte
    d.polygon([(300, 212), (302, 182), (304, 182), (306, 212)], fill=22)
    d.rectangle([301, 178, 305, 181], fill=7)
    d.point([(303, 179)], fill=9)
    return to_image(np.array(cv))


def silhouette(seed: int, base: float, amps, color: int, rim: int | None, extra=None) -> Image.Image:
    a = np.zeros((H, W), dtype=np.uint8)
    prof = ridge(seed, base, amps)
    for x in range(W):
        top = int(prof[x])
        a[top:, x] = color
        if rim is not None and 0 <= top < H:
            a[top, x] = rim
    if extra:
        extra(a)
    return to_image(a)


def far_extra(a: np.ndarray) -> None:
    rng = random.Random(11)
    for x0 in range(20, W - 20, 90):  # agujas de la Ciudadela, muy lejos
        x = x0 + rng.randrange(0, 40)
        h = rng.randrange(25, 60)
        top = int(np.argmax(a[:, x] > 0)) - h
        a[top:top + h + 2, x:x + 3] = 23
        a[top - 4:top, x + 1] = 23


def mid_extra(a: np.ndarray) -> None:
    rng = random.Random(5)
    x = 10
    while x < W - 40:  # casas de la aldea, algunas aún con una ventana encendida
        w = rng.randrange(22, 40)
        h = rng.randrange(18, 34)
        ground = int(np.argmax(a[:, x + w // 2] > 0))
        top = ground - h
        a[top:ground + 1, x:x + w] = 24
        i = 0
        while x - 1 + i < x + w + 1 - i and top - 1 - i >= 0:  # tejado a dos aguas
            a[top - 1 - i, x - 1 + i:x + w + 1 - i] = 24
            i += 1
        if rng.random() < 0.4:
            wx, wy = x + rng.randrange(4, w - 6), top + rng.randrange(5, h - 8)
            a[wy:wy + 3, wx:wx + 2] = 6
            a[wy, wx] = 7
        x += w + rng.randrange(20, 70)


def near_extra(a: np.ndarray) -> None:
    rng = random.Random(9)
    for x0 in range(30, W, 160):  # árboles secos
        x = x0 + rng.randrange(0, 60)
        ground = int(np.argmax(a[:, x] > 0))
        h = rng.randrange(60, 100)
        img = Image.fromarray(a, "L")
        d = ImageDraw.Draw(img)
        d.line([(x, ground), (x, ground - h)], fill=25, width=4)
        for _ in range(6):
            by = ground - rng.randrange(h // 3, h)
            bl = rng.randrange(10, 26)
            sgn = rng.choice([-1, 1])
            d.line([(x, by), (x + sgn * bl, by - bl // 2)], fill=25, width=2)
            d.line([(x + sgn * bl, by - bl // 2), (x + sgn * (bl + 5), by - bl // 2 - 6)], fill=25, width=1)
        a[:] = np.array(img)
    for x in range(0, W, 12):  # valla rota
        ground = int(np.argmax(a[:, x] > 0))
        if rng.random() < 0.75:
            a[ground - rng.randrange(8, 14):ground, x:x + 2] = 25


# ----------------------------------------------------------------- SpriteFrames .tres
def write_spriteframes(name: str, png: str, anims: dict, fw: int, fh: int) -> None:
    subs, anim_txt = [], []
    sid = 0
    for row, (anim, (frames, fps, loop)) in enumerate(anims.items()):
        refs = []
        for col in range(len(frames)):
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="f{sid}"]\natlas = ExtResource("1")\n'
                        f'region = Rect2({col * fw}, {row * fh}, {fw}, {fh})\n')
            refs.append(f'{{\n"duration": 1.0,\n"texture": SubResource("f{sid}")\n}}')
        anim_txt.append(f'{{\n"frames": [{", ".join(refs)}],\n"loop": {"true" if loop else "false"},\n'
                        f'"name": &"{anim}",\n"speed": {float(fps)}\n}}')
    txt = (f'[gd_resource type="SpriteFrames" load_steps={sid + 2} format=3]\n\n'
           f'[ext_resource type="Texture2D" path="res://assets/art/{png}" id="1"]\n\n'
           + "\n".join(subs) + "\n[resource]\nanimations = [" + ", ".join(anim_txt) + "]\n")
    (FRAMES_OUT / f"{name}.tres").write_text(txt)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    FRAMES_OUT.mkdir(parents=True, exist_ok=True)

    h = hero_frames()
    sheet([f for f, _, _ in h.values()], HW, HH).save(OUT / "hero.png")
    write_spriteframes("hero", "hero.png", h, HW, HH)

    e = bearer_frames()
    sheet([f for f, _, _ in e.values()], EW, EH).save(OUT / "hollowed_bearer.png")
    write_spriteframes("hollowed_bearer", "hollowed_bearer.png", e, EW, EH)

    sheet([slash_frames()], 32, 24).save(OUT / "slash.png")
    tiles().save(OUT / "tiles.png")
    lantern_post().save(OUT / "lantern_post.png")

    sky().save(OUT / "bg_sky.png")
    silhouette(1, 205, [(2, 14), (5, 6), (11, 3)], 23, 22, far_extra).save(OUT / "bg_far.png")
    silhouette(2, 245, [(1, 10), (3, 6), (7, 3)], 24, 23, mid_extra).save(OUT / "bg_mid.png")
    silhouette(4, 290, [(2, 6), (4, 4), (9, 2)], 25, None, near_extra).save(OUT / "bg_near.png")

    # hoja de contacto ×4 para revisar de un vistazo
    preview = Image.new("RGBA", (W, 200), (11, 13, 28, 255))
    x = 4
    for f in ["hero.png", "hollowed_bearer.png", "slash.png", "tiles.png", "lantern_post.png"]:
        im = Image.open(OUT / f)
        preview.alpha_composite(im, (x, 4))
        x += im.width + 8
    preview.resize((W * 2, 400), Image.NEAREST).save(ROOT / "tools" / "art" / "preview.png")
    print("Arte generado en", OUT)


if __name__ == "__main__":
    main()
