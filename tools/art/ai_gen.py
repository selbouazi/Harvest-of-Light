#!/usr/bin/env python3
"""Genera las imágenes base del arte con FLUX.2 en Cloudflare Workers AI (cupo gratis).

    python3 tools/art/ai_gen.py              # genera lo que falte
    python3 tools/art/ai_gen.py hero_run_a   # (re)genera ids concretos
    python3 tools/art/ai_gen.py --list

Las imágenes crudas van a tools/art/raw/ (no se suben a git). Después:
    python3 tools/art/process_ai.py          # recorta, iguala color, escala → assets/art/

Credenciales: el token NO está en el repo. En la sesión cloud lo inyecta el proxy.
En local: exporta CF_API_TOKEN. El Account ID va en tools/art/cf_account.txt o CF_ACCOUNT_ID.
Las semillas fijas hacen que cada asset sea reproducible con el mismo modelo.
"""
from __future__ import annotations

import base64
import io
import json
import os
import sys
import time
from pathlib import Path

import requests
from PIL import Image

HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
MODEL = "@cf/black-forest-labs/flux-2-dev"

STYLE = ("hand-painted ink and watercolor illustration, muted desaturated colors, "
         "soft textured brush strokes, dark fairy-tale mood, clean readable silhouette")
ISO = "full body, side view, isolated on a plain pure white background, no ground, no shadow"
SAME_HERO = ("The exact same small hooded wanderer from the reference image: same dark slate-blue "
             "tattered cloak, same face hidden in shadow with two tiny glowing amber eyes, same long "
             "golden scarf, same thin needle sword, same style and colors.")
SAME_BEARER = ("The exact same hollow creature from the reference image: same pale cracked mask with "
               "one glowing orange eye slit, same grey rags, same huge empty wicker basket on its back, "
               "same long thin arms, same style and colors.")

# id: (prompt, width, height, seed, [refs])
ASSETS: dict[str, tuple[str, int, int, int, list[str]]] = {
    # --- Errante (protagonista). hero_ref es el concepto aprobado.
    "hero_ref": (f"2D game character concept, a small hooded wanderer in a long dark slate-blue tattered "
                 f"cloak reaching the ground, face hidden in shadow with two tiny glowing amber eyes, a long "
                 f"golden scarf flowing behind, holding a thin needle-like sword, facing right, {STYLE}, {ISO}",
                 768, 1024, 1, []),
    "hero_idle_b": (f"{SAME_HERO} Pose: standing still, calm, breathing, sword lowered, scarf resting. Facing right, {ISO}", 768, 1024, 11, ["hero_ref"]),
    "hero_run_a": (f"{SAME_HERO} Pose: running to the right, left leg forward touching the ground, right leg back, leaning forward, cloak flowing behind. {ISO}", 768, 1024, 21, ["hero_ref"]),
    "hero_run_b": (f"{SAME_HERO} Pose: running to the right, mid-stride with both legs together under the body, body slightly higher, cloak flowing behind. {ISO}", 768, 1024, 22, ["hero_ref"]),
    "hero_run_c": (f"{SAME_HERO} Pose: running to the right, right leg forward touching the ground, left leg back, leaning forward, cloak flowing behind. {ISO}", 768, 1024, 23, ["hero_ref"]),
    "hero_jump": (f"{SAME_HERO} Pose: jumping upward, knees tucked up, cloak hanging down below, scarf trailing down. Facing right, {ISO}", 768, 1024, 31, ["hero_ref"]),
    "hero_fall": (f"{SAME_HERO} Pose: falling downward, legs dangling, cloak and scarf billowing upward. Facing right, {ISO}", 768, 1024, 32, ["hero_ref"]),
    "hero_windup": (f"{SAME_HERO} Pose: preparing a slash, sword drawn back behind the body, body coiled, weight on back foot. Facing right, {ISO}", 768, 1024, 41, ["hero_ref"]),
    "hero_strike": (f"{SAME_HERO} Pose: lunging forward in a fast horizontal sword slash to the right, arm fully extended, cloak and scarf whipping back. {ISO}", 768, 1024, 42, ["hero_ref"]),
    "hero_strike_up": (f"{SAME_HERO} Pose: slashing the sword straight upward above the head, arm raised high. Facing right, {ISO}", 768, 1024, 43, ["hero_ref"]),
    "hero_strike_down": (f"{SAME_HERO} Pose: in mid-air, stabbing the sword straight down below the feet, legs tucked. Facing right, {ISO}", 768, 1024, 44, ["hero_ref"]),
    "hero_dodge": (f"{SAME_HERO} Pose: a low fast dash forward to the right, body crouched almost horizontal, cloak streaming back like smoke. {ISO}", 1024, 768, 51, ["hero_ref"]),
    "hero_hurt": (f"{SAME_HERO} Pose: recoiling backward after being hit, head thrown back, cloak flaring, off balance. Facing right, {ISO}", 768, 1024, 61, ["hero_ref"]),
    "hero_heal": (f"{SAME_HERO} Pose: kneeling on one knee, both hands at the chest holding a small glowing golden light, the scarf glowing softly. Facing right, {ISO}", 768, 1024, 71, ["hero_ref"]),
    "hero_dead": (f"{SAME_HERO} Pose: collapsed lying on the ground on its side, defeated, sword dropped beside. Side view, {ISO}", 1024, 768, 81, ["hero_ref"]),

    # --- Portador vaciado (enemigo común)
    "bearer_ref": (f"2D game enemy concept, a hunched gaunt hollow creature walking to the right, wearing a pale "
                   f"cracked porcelain mask with one glowing orange eye slit, tattered grey rags, very long thin "
                   f"arms hanging low, carrying a huge empty broken wicker basket strapped on its back, {STYLE}, {ISO}",
                   1024, 1024, 101, []),
    "bearer_walk_b": (f"{SAME_BEARER} Pose: walking to the right, the other leg forward, arms swinging, hunched. {ISO}", 1024, 1024, 102, ["bearer_ref"]),
    "bearer_telegraph": (f"{SAME_BEARER} Pose: rearing up tall, both long arms raised high above the head ready to strike, eye glowing bright. Facing right, {ISO}", 1024, 1024, 103, ["bearer_ref"]),
    "bearer_lunge": (f"{SAME_BEARER} Pose: lunging violently forward to the right, arms thrust forward with claws, body stretched low. {ISO}", 1024, 1024, 104, ["bearer_ref"]),
    "bearer_recover": (f"{SAME_BEARER} Pose: exhausted and slumped forward, arms dragging on the ground, eye dim. Facing right, {ISO}", 1024, 1024, 105, ["bearer_ref"]),
    "bearer_stagger": (f"{SAME_BEARER} Pose: staggering backward after being hit, arms flailing, off balance. Facing right, {ISO}", 1024, 1024, 106, ["bearer_ref"]),

    # --- Escenario
    "bg_far": (f"Wide hand-painted 2D game background, side view, distant misty cliffs and the silhouette of a "
               f"far citadel with thin spires, one tiny warm lighthouse light on the horizon, a pale moon behind "
               f"thin clouds, layered deep teal and blue fog, empty lower third, no foreground, no characters, {STYLE}",
               1536, 864, 201, []),
    "bg_mid": (f"A row of crooked ruined wooden village houses with a few glowing amber windows and hanging lanterns, "
               f"dark blue-grey silhouettes with soft painted detail, side view, {STYLE}, isolated on a plain pure white background",
               1536, 640, 202, []),
    "bg_near": (f"Dark silhouettes of twisted dead trees and a broken wooden fence, foreground elements, very dark "
                f"desaturated blue-black, side view, {STYLE}, isolated on a plain pure white background",
                1536, 640, 203, []),
    "fg_roots": (f"Very dark hanging roots and thorny vines silhouette, foreground decoration, almost black, {STYLE}, isolated on a plain pure white background",
                 1024, 768, 204, []),
    "ground": (f"Seamless tileable hand-painted texture of old dark stone ground seen from the side as a cross-section, "
               f"a mossy uneven top edge with tiny amber crystals, dark blue-grey stone below, {STYLE}, fills the whole image",
               1024, 512, 205, []),
    "slash": ("A single thin crescent-shaped sword slash arc of bright white-gold light with soft glow and small sparks, "
              "curving from top to bottom, on a pure black background, game visual effect", 1024, 768, 301, []),
    "lantern_off": (f"An old iron lantern hanging on a crooked wooden post, unlit and cold, {STYLE}, {ISO}", 512, 1024, 401, []),
    "lantern_on": ("The exact same old iron lantern on a crooked wooden post from the reference image, same style, "
                   "but now lit with a warm bright amber flame glowing inside. isolated on a plain pure white background",
                   512, 1024, 402, ["lantern_off"]),
}


def account_id() -> str:
    env = os.environ.get("CF_ACCOUNT_ID")
    if env:
        return env
    return (HERE / "cf_account.txt").read_text().strip()


def generate(asset_id: str) -> Path:
    prompt, w, h, seed, refs = ASSETS[asset_id]
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id()}/ai/run/{MODEL}"
    token = os.environ.get("CF_API_TOKEN", "proxy-injected")
    files = {"prompt": (None, prompt), "width": (None, str(w)), "height": (None, str(h)),
             "steps": (None, "28"), "seed": (None, str(seed))}
    for i, ref in enumerate(refs):
        im = Image.open(RAW / f"{ref}.png").convert("RGB")
        im.thumbnail((640, 640))
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=92)
        files[f"input_image_{i}"] = (f"{ref}.jpg", buf.getvalue(), "image/jpeg")
    for attempt in range(4):
        r = requests.post(url, headers={"Authorization": f"Bearer {token}"}, files=files, timeout=240)
        try:
            d = r.json()
        except ValueError:
            d = {"success": False, "errors": [r.text[:200]]}
        if d.get("success"):
            out = RAW / f"{asset_id}.png"
            out.write_bytes(base64.b64decode(d["result"]["image"]))
            return out
        print(f"  {asset_id}: intento {attempt + 1} falló: {json.dumps(d.get('errors'))[:300]}")
        time.sleep(5 * (attempt + 1))
    raise RuntimeError(f"No se pudo generar {asset_id}")


def main(argv: list[str]) -> None:
    RAW.mkdir(exist_ok=True)
    if "--list" in argv:
        for k in ASSETS:
            print(("✓ " if (RAW / f"{k}.png").exists() else "· ") + k)
        return
    force = [a for a in argv if not a.startswith("-")]
    # Las referencias primero.
    order = sorted(ASSETS, key=lambda k: len(ASSETS[k][4]))
    for k in order:
        if force and k not in force:
            continue
        if not force and (RAW / f"{k}.png").exists():
            continue
        t = time.time()
        generate(k)
        print(f"✓ {k} ({time.time() - t:.1f}s)")


if __name__ == "__main__":
    main(sys.argv[1:])
