#!/usr/bin/env python3
"""Convierte las imágenes crudas de tools/art/raw/ en assets del juego.

    python3 tools/art/process_ai.py

- Personajes: quita el fondo (rembg), iguala el color a la referencia, normaliza
  escala y anclaje (pies abajo, cuerpo centrado) y empaqueta hojas + SpriteFrames.
- Fondos: recorta, oscurece y genera texturas en bucle.
Las texturas se exportan a 4× la resolución del mundo (el mundo es 640×360);
los nodos las dibujan con scale = 0.25 (ver SCALE).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from rembg import new_session, remove

HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
ROOT = HERE.parents[1]
OUT = ROOT / "assets" / "art" / "hd"
FRAMES = ROOT / "assets" / "art" / "frames"
SCALE = 4  # px de textura por px de mundo

_session = None


def cutout(img: Image.Image) -> Image.Image:
    global _session
    if _session is None:
        _session = new_session("isnet-general-use")
    out = remove(img.convert("RGB"), session=_session, post_process_mask=True)
    a = np.array(out)
    alpha = a[..., 3].astype(np.float32)
    rgb = a[..., :3].astype(np.float32)
    alpha[alpha < 24] = 0
    a[..., 3] = alpha.astype(np.uint8)
    # Descontamina: los píxeles semitransparentes tiran hacia oscuro en vez de a blanco.
    semi = (alpha > 0) & (alpha < 250)
    k = (alpha[semi] / 255.0)[:, None]
    a[..., :3][semi] = (rgb[semi] * k + rgb[semi] * (1 - k) * 0.25).astype(np.uint8)
    return Image.fromarray(a, "RGBA")


def color_match(img: Image.Image, ref: Image.Image) -> Image.Image:
    a = np.array(img).astype(np.float32)
    r = np.array(ref).astype(np.float32)
    ma, mr = a[..., 3] > 200, r[..., 3] > 200
    for c in range(3):
        sa, sr = a[..., c][ma], r[..., c][mr]
        if sa.size and sr.size:
            a[..., c] = (a[..., c] - sa.mean()) / (sa.std() + 1e-3) * sr.std() + sr.mean()
    a[..., :3] = np.clip(a[..., :3], 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def bbox_alpha(img: Image.Image) -> tuple[int, int, int, int]:
    a = np.array(img)[..., 3] > 40
    ys, xs = np.nonzero(a)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def body_metrics(img: Image.Image) -> tuple[float, float, int]:
    """sqrt(área opaca) como tamaño, x del centroide, y de los pies."""
    a = np.array(img)[..., 3] > 120
    ys, xs = np.nonzero(a)
    return float(np.sqrt(a.sum())), float(xs.mean()), int(ys.max())


def char_frames(ids: list[str], ref_id: str, frame_world: tuple[int, int], size_world: float,
                overrides: dict[str, float] | None = None) -> dict[str, Image.Image]:
    """Devuelve frames RGBA de frame_world*SCALE px, pies en el borde inferior."""
    overrides = overrides or {}
    ref = cutout(Image.open(RAW / f"{ref_id}.png"))
    ref_size, _, _ = body_metrics(ref)
    fw, fh = frame_world[0] * SCALE, frame_world[1] * SCALE
    out = {}
    for i in ids:
        src = ref if i == ref_id else color_match(cutout(Image.open(RAW / f"{i}.png")), ref)
        s, cx, feet = body_metrics(src)
        k = (size_world * SCALE / ref_size) * (ref_size / s) * overrides.get(i, 1.0)
        im = src.resize((round(src.width * k), round(src.height * k)), Image.LANCZOS)
        canvas = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        canvas.alpha_composite(im, (round(fw / 2 - cx * k), round(fh - 2 - feet * k)))
        out[i] = canvas
    return out


def write_sheet(name: str, anims: dict[str, tuple[list[Image.Image], float, bool]], fw: int, fh: int) -> None:
    cols = max(len(f) for f, _, _ in anims.values())
    sheet = Image.new("RGBA", (cols * fw, len(anims) * fh), (0, 0, 0, 0))
    for r, (frames, _, _) in enumerate(anims.values()):
        for c, fr in enumerate(frames):
            sheet.alpha_composite(fr, (c * fw, r * fh))
    sheet.save(OUT / f"{name}.png", optimize=True)
    subs, anim_txt, sid = [], [], 0
    for r, (anim, (frames, fps, loop)) in enumerate(anims.items()):
        refs = []
        for c in range(len(frames)):
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="f{sid}"]\natlas = ExtResource("1")\n'
                        f'region = Rect2({c * fw}, {r * fh}, {fw}, {fh})\n')
            refs.append(f'{{\n"duration": 1.0,\n"texture": SubResource("f{sid}")\n}}')
        anim_txt.append(f'{{\n"frames": [{", ".join(refs)}],\n"loop": {"true" if loop else "false"},\n'
                        f'"name": &"{anim}",\n"speed": {float(fps)}\n}}')
    (FRAMES / f"{name}.tres").write_text(
        f'[gd_resource type="SpriteFrames" load_steps={sid + 2} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="res://assets/art/hd/{name}.png" id="1"]\n\n'
        + "\n".join(subs) + "\n[resource]\nanimations = [" + ", ".join(anim_txt) + "]\n")


def hero() -> None:
    ids = ["hero_ref", "hero_idle_b", "hero_run_a", "hero_run_b", "hero_run_c", "hero_jump", "hero_fall",
           "hero_windup", "hero_strike", "hero_strike_up", "hero_strike_down", "hero_dodge", "hero_hurt",
           "hero_heal", "hero_dead"]
    ids = [i for i in ids if (RAW / f"{i}.png").exists()]
    f = char_frames(ids, "hero_ref", (80, 52), 23.0,
                    overrides={"hero_dodge": 0.95, "hero_dead": 0.9, "hero_heal": 1.0})
    g = lambda *names: [f[n] for n in names if n in f]
    anims = {
        "idle": (g("hero_ref", "hero_idle_b"), 2.5, True),
        "run": (g("hero_run_a", "hero_run_b", "hero_run_c", "hero_run_b"), 10.0, True),
        "jump": (g("hero_jump"), 1.0, False),
        "fall": (g("hero_fall"), 1.0, False),
        "attack": (g("hero_windup", "hero_strike", "hero_strike"), 0.0, False),
        "attack_up": (g("hero_windup", "hero_strike_up", "hero_strike_up"), 0.0, False),
        "attack_down": (g("hero_jump", "hero_strike_down", "hero_strike_down"), 0.0, False),
        "dodge": (g("hero_dodge"), 1.0, False),
        "hurt": (g("hero_hurt"), 1.0, False),
        "heal": (g("hero_heal"), 1.0, False),
        "dead": (g("hero_dead"), 1.0, False),
    }
    anims = {k: v for k, v in anims.items() if v[0]}
    write_sheet("hero", anims, 80 * SCALE, 52 * SCALE)


def bearer() -> None:
    ids = ["bearer_ref", "bearer_walk_b", "bearer_telegraph", "bearer_lunge", "bearer_recover", "bearer_stagger"]
    ids = [i for i in ids if (RAW / f"{i}.png").exists()]
    f = char_frames(ids, "bearer_ref", (72, 52), 25.0)
    g = lambda *names: [f[n] for n in names if n in f]
    anims = {
        "walk": (g("bearer_ref", "bearer_walk_b"), 3.0, True),
        "telegraph": (g("bearer_telegraph"), 1.0, False),
        "lunge": (g("bearer_lunge"), 1.0, False),
        "recover": (g("bearer_recover"), 1.0, False),
        "stagger": (g("bearer_stagger") or g("bearer_recover"), 1.0, False),
    }
    anims = {k: v for k, v in anims.items() if v[0]}
    write_sheet("hollowed_bearer", anims, 72 * SCALE, 52 * SCALE)


def tint(img: Image.Image, color: tuple[int, int, int], amount: float, darken: float = 1.0) -> Image.Image:
    a = np.array(img).astype(np.float32)
    a[..., :3] = (a[..., :3] * (1 - amount) + np.array(color) * amount) * darken
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def night_grade(img: Image.Image) -> Image.Image:
    """Pasa una escena a noche: baja exposición, empuja a azul verdoso y conserva las luces cálidas."""
    a = np.array(img).astype(np.float32) / 255.0
    rgb = a[..., :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    warm = np.clip((rgb[..., 0] - rgb[..., 2]) * 3.0, 0, 1) * np.clip(lum * 2 - 0.6, 0, 1)
    night = np.stack([lum * 0.22 + 0.02, lum * 0.36 + 0.04, lum * 0.48 + 0.07], axis=-1)
    out = night * (1 - warm[..., None]) + rgb * warm[..., None] * 1.1
    # más oscuro arriba (cielo) para que el horizonte respire
    h = out.shape[0]
    out *= (0.75 + 0.35 * np.linspace(0, 1, h) ** 0.7)[:, None, None]
    a[..., :3] = np.clip(out, 0, 1)
    return Image.fromarray((a * 255).astype(np.uint8), "RGBA")


def crop_alpha(img: Image.Image) -> Image.Image:
    return img.crop(bbox_alpha(img))


def seamless_x(img: Image.Image, band: int) -> Image.Image:
    a = np.array(img.convert("RGBA")).astype(np.float32)
    w = a.shape[1]
    left, right = a[:, :band], a[:, w - band:]
    t = np.linspace(0, 1, band)[None, :, None]
    a[:, :band] = right * (1 - t) + left * t
    return Image.fromarray(a[:, :w - band].astype(np.uint8), "RGBA")


def scenery() -> None:
    far = night_grade(Image.open(RAW / "bg_far.png").convert("RGBA"))
    far.resize((1536, 864), Image.LANCZOS).save(OUT / "bg_far.png", optimize=True)  # escala 0.5 → 768×432 mundo

    mid = crop_alpha(cutout(Image.open(RAW / "bg_mid.png")))
    mid = tint(mid, (40, 52, 80), 0.35, 0.8)
    mid.save(OUT / "bg_mid.png", optimize=True)

    near = crop_alpha(cutout(Image.open(RAW / "bg_near.png")))
    near = tint(near, (10, 12, 22), 0.75, 0.6)
    near.save(OUT / "bg_near.png", optimize=True)

    roots = crop_alpha(cutout(Image.open(RAW / "fg_roots.png")))
    roots = tint(roots, (6, 7, 14), 0.85, 0.5)
    roots.save(OUT / "fg_roots.png", optimize=True)

    g = Image.open(RAW / "ground.png").convert("RGBA")
    g = seamless_x(g, 160)
    ga = np.array(g).astype(np.float32)
    lum = ga[..., :3].mean(axis=2, keepdims=True)
    ga[..., :3] = (ga[..., :3] * 0.55 + lum * 0.45) * 0.62  # menos saturado y más oscuro
    g = Image.fromarray(np.clip(ga, 0, 255).astype(np.uint8), "RGBA")
    g = g.resize((256 * 2, 128 * 2), Image.LANCZOS)  # 128×64 mundo con escala 0.25 (tile 512px)
    g.save(OUT / "ground.png", optimize=True)

    s = np.array(Image.open(RAW / "slash.png").convert("RGB")).astype(np.float32)
    lum = s.max(axis=2)
    alpha = np.clip((lum - 18) / 200.0, 0, 1) ** 0.8
    rgba = np.dstack([np.clip(s * 1.1 + 20, 0, 255), alpha * 255]).astype(np.uint8)
    sl = crop_alpha(Image.fromarray(rgba, "RGBA"))
    sl.thumbnail((48 * SCALE, 36 * SCALE), Image.LANCZOS)
    sl.save(OUT / "slash.png", optimize=True)

    lanterns = []
    for n in ("lantern_off", "lantern_on"):
        if (RAW / f"{n}.png").exists():
            im = crop_alpha(cutout(Image.open(RAW / f"{n}.png")))
            k = 44 * SCALE / im.height
            lanterns.append(im.resize((round(im.width * k), 44 * SCALE), Image.LANCZOS))
    if len(lanterns) == 1:  # sin versión encendida generada: se ilumina el cristal por código
        a = np.array(lanterns[0]).astype(np.float32)
        lum = a[..., :3].mean(axis=2) / 255.0
        glass = np.clip((lum - 0.45) * 3.0, 0, 1) * (a[..., 3] > 0)
        warm = np.array([255, 196, 90], np.float32)
        a[..., :3] = a[..., :3] * (1 - glass[..., None]) + warm * glass[..., None]
        lanterns.append(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA"))
    if lanterns:
        w = max(l.width for l in lanterns)
        sheet = Image.new("RGBA", (w * len(lanterns), 44 * SCALE), (0, 0, 0, 0))
        for i, l in enumerate(lanterns):
            sheet.alpha_composite(l, (i * w + (w - l.width) // 2, 0))
        sheet.save(OUT / "lantern.png", optimize=True)

    fog()


def fog() -> None:
    """Niebla procedural en bucle (ruido suave)."""
    rng = np.random.default_rng(5)
    w, h = 1024, 256
    acc = np.zeros((h, w), np.float32)
    for octave, amp in [(8, 1.0), (16, 0.5), (32, 0.25)]:
        small = rng.random((max(2, h * octave // w), octave)).astype(np.float32)
        small = np.concatenate([small, small[:, :1]], axis=1)
        im = Image.fromarray((small * 255).astype(np.uint8)).resize((w + w // octave, h), Image.BICUBIC)
        acc += np.array(im, np.float32)[:, :w] / 255 * amp
    acc /= acc.max()
    vert = np.sin(np.linspace(0, np.pi, h))[:, None] ** 1.5
    alpha = np.clip((acc - 0.35) * 1.6, 0, 1) * vert * 140
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = (110, 140, 170)
    rgba[..., 3] = alpha.astype(np.uint8)
    Image.fromarray(rgba, "RGBA").filter(ImageFilter.GaussianBlur(6)).save(OUT / "fog.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    FRAMES.mkdir(parents=True, exist_ok=True)
    hero()
    bearer()
    scenery()
    print("Assets HD en", OUT)
