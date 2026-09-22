#!/usr/bin/env python3
"""Build assets/images/familiars/cat.riv from the Shadow Cat rig layers.

Writes a Rive runtime file (format 7.0, read by the pure-Dart `rive` 0.13
package the app uses) directly, without the Rive editor:

* one artboard ("Cat", 512 x 512) holding every rig layer as an embedded
  PNG image, placed from layout.json and parented to simple bones
  (root, body, head, ears, front legs, tail);
* linear animations for each action, mood and the hop;
* a state machine named "Familiar" with the inputs the app drives
  (lib/widgets/familiar/rive_familiar.dart):
    action (number) 0 idle, 1 walk, 2 sit, 3 sleep, 4 groom, 5 stretch
    mood   (number) 0 sleepy, 1 watchful, 2 content, 3 joyful
    hop    (trigger)
  `facingLeft` and `walking` are intentionally not exposed: the den
  mirrors the artboard and walking is covered by action 1.

State machine layers, applied in order (later layers win):
  1. Mood   - eyes and mouth for the current mood, with a periodic blink.
  2. Action - body motion; sleep, groom and stretch also override the face.
  3. Hop    - one-shot squash-and-stretch + mouth_excited on the trigger.

Usage (from the repo root; needs Pillow):
    python3 art/familiars/cat/tools/build_cat_riv.py

Property and type keys below come from the generated sources of
rive 0.13.20 (lib/src/generated/**_base.dart).
"""

from __future__ import annotations

import io
import json
import math
import struct
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
RIG = HERE.parent
REPO = RIG.parent.parent.parent
OUT = REPO / "assets" / "images" / "familiars" / "cat.riv"

# ---------------------------------------------------------------------------
# Framing: the square of the 2048 canvas that becomes the artboard.
# Paws sit near the bottom edge; headroom above is for the Zzz.
# ---------------------------------------------------------------------------
ARTBOARD = 512
CROP_SIZE = 1760
CROP_X = 1024 - CROP_SIZE // 2
CROP_Y = 1940 - CROP_SIZE
S = ARTBOARD / CROP_SIZE

FPS = 60

# ---------------------------------------------------------------------------
# Rive type keys.
# ---------------------------------------------------------------------------
T_BACKBOARD = 23
T_ARTBOARD = 1
T_NODE = 2
T_IMAGE = 100
T_IMAGE_ASSET = 105
T_FILE_ASSET_CONTENTS = 106
T_LINEAR_ANIMATION = 31
T_KEYED_OBJECT = 25
T_KEYED_PROPERTY = 26
T_KEYFRAME_DOUBLE = 30
T_STATE_MACHINE = 53
T_SM_NUMBER = 56
T_SM_TRIGGER = 58
T_SM_LAYER = 57
T_ANY_STATE = 62
T_ENTRY_STATE = 63
T_EXIT_STATE = 64
T_ANIMATION_STATE = 61
T_STATE_TRANSITION = 65
T_TRIGGER_CONDITION = 68
T_NUMBER_CONDITION = 70

# ---------------------------------------------------------------------------
# Rive property keys -> (key, field type).
# ---------------------------------------------------------------------------
UINT, DOUBLE, STRING, BYTES, BOOL = "uint", "double", "string", "bytes", "bool"
P = {
    "name": (4, STRING),
    "parentId": (5, UINT),
    "width": (7, DOUBLE),
    "height": (8, DOUBLE),
    "x": (13, DOUBLE),
    "y": (14, DOUBLE),
    "rotation": (15, DOUBLE),
    "scaleX": (16, DOUBLE),
    "scaleY": (17, DOUBLE),
    "opacity": (18, DOUBLE),
    "clip": (196, BOOL),
    "defaultStateMachineId": (236, UINT),
    # Image
    "imageAssetId": (206, UINT),
    "imageOriginX": (380, DOUBLE),
    "imageOriginY": (381, DOUBLE),
    # Assets
    "assetName": (203, STRING),
    "fileAssetId": (204, UINT),
    "assetHeight": (207, DOUBLE),
    "assetWidth": (208, DOUBLE),
    "bytes": (212, BYTES),
    # Animation
    "animationName": (55, STRING),
    "fps": (56, UINT),
    "duration": (57, UINT),
    "loopValue": (59, UINT),
    "objectId": (51, UINT),
    "propertyKey": (53, UINT),
    "frame": (67, UINT),
    "interpolationType": (68, UINT),
    "value": (70, DOUBLE),
    # State machine
    "smName": (138, STRING),
    "numberValue": (140, DOUBLE),
    "animationId": (149, UINT),
    "stateToId": (151, UINT),
    "transitionFlags": (152, UINT),
    "transitionDuration": (158, UINT),
    "exitTime": (160, UINT),
    "inputId": (155, UINT),
    "opValue": (156, UINT),
    "conditionValue": (157, DOUBLE),
}

# Animated property keys (TransformComponent / WorldTransformComponent / Node).
K_X, K_Y, K_ROT, K_SX, K_SY, K_OPACITY = 13, 14, 15, 16, 17, 18

HOLD, LINEAR = 0, 1
LOOP, ONE_SHOT = 1, 0

# StateTransitionFlags
EXIT_TIME = 1 << 2
EXIT_TIME_PERCENT = 1 << 3
OP_EQUAL = 0


# ---------------------------------------------------------------------------
# Binary writer.
# ---------------------------------------------------------------------------
class Writer:
    def __init__(self) -> None:
        self.buf = bytearray()

    def varuint(self, v: int) -> None:
        if v < 0:
            raise ValueError(f"negative varuint {v}")
        while True:
            b = v & 0x7F
            v >>= 7
            if v:
                self.buf.append(b | 0x80)
            else:
                self.buf.append(b)
                return

    def obj(self, type_key: int, **props) -> None:
        self.varuint(type_key)
        for name, value in props.items():
            if value is None:
                continue
            key, kind = P[name]
            self.varuint(key)
            if kind == UINT:
                self.varuint(int(value))
            elif kind == DOUBLE:
                self.buf += struct.pack("<f", float(value))
            elif kind == BOOL:
                self.buf.append(1 if value else 0)
            elif kind == STRING:
                data = value.encode("utf-8")
                self.varuint(len(data))
                self.buf += data
            elif kind == BYTES:
                self.varuint(len(value))
                self.buf += value
        self.varuint(0)


# ---------------------------------------------------------------------------
# Rig.
# ---------------------------------------------------------------------------
def a(x: float, y: float) -> tuple[float, float]:
    """Canvas pixel -> artboard coordinate."""
    return ((x - CROP_X) * S, (y - CROP_Y) * S)


layout = {p["name"]: p for p in json.loads((RIG / "layout.json").read_text())["parts"]}
layer_files = {
    f.stem.split("_", 1)[1]: f for f in (RIG / "layers_fullcanvas").glob("*.png")
}


class Component:
    def __init__(self, name: str, kind: str, parent: "Component | None", pivot):
        self.name = name
        self.kind = kind  # "node" | "image"
        self.parent = parent
        self.pivot = pivot  # artboard coords
        self.children: list[Component] = []
        self.id = -1
        self.asset = -1
        self.origin = (0.5, 0.5)
        self.opacity = 1.0
        if parent:
            parent.children.append(self)


assets: list[tuple[str, bytes, int, int]] = []


def add_asset(name: str, img: Image.Image) -> int:
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    assets.append((name, buf.getvalue(), img.width, img.height))
    return len(assets) - 1


def rig_image(name: str, parent: Component) -> Component:
    part = layout[name]
    x, y, w, h = part["x"], part["y"], part["width"], part["height"]
    full = Image.open(layer_files[name]).convert("RGBA")
    crop = full.crop((x, y, x + w, y + h))
    size = (max(1, round(w * S)), max(1, round(h * S)))
    img = crop.resize(size, Image.LANCZOS)
    px, py = part["pivot"]
    c = Component(name, "image", parent, a(px, py))
    c.asset = add_asset(name, img)
    c.origin = ((px - x) / w, (py - y) / h)
    c.opacity = 1.0 if part["visible_by_default"] else 0.0
    return c


def fx_image(name: str, parent: Component, centre, height_px: float) -> Component:
    src = Image.open(RIG / "parts" / f"{name}.png").convert("RGBA")
    src = src.crop(src.getbbox())
    h = height_px * S
    w = src.width * h / src.height
    img = src.resize((max(1, round(w)), max(1, round(h))), Image.LANCZOS)
    c = Component(name, "image", parent, a(*centre))
    c.asset = add_asset(name, img)
    c.opacity = 0.0
    return c


def node(name: str, parent: Component | None, pivot_canvas) -> Component:
    return Component(name, "node", parent, a(*pivot_canvas))


# Children are listed front-most first: Rive draws the first drawable in
# hierarchy order on top.
root = node("root", None, layout["body"]["pivot"])
fx_zzz = fx_image("fx_zzz", root, (1400, 560), 230)
head = node("head_bone", root, layout["head"]["pivot"])
FACE_FRONT_TO_BACK = [
    "nose",
    "mouth_lick",
    "mouth_yawn",
    "mouth_surprised",
    "mouth_excited",
    "mouth_happy",
    "mouth_neutral",
    "whiskers_right",
    "whiskers_left",
    "eyes_happy_right",
    "eyes_happy_left",
    "eyes_closed_right",
    "eyes_closed_left",
    "eyelid_right",
    "eyelid_left",
    "highlight_right",
    "highlight_left",
    "pupil_right",
    "pupil_left",
    "iris_right",
    "iris_left",
    "head",
]
face = {n: rig_image(n, head) for n in FACE_FRONT_TO_BACK}
ear_r = node("ear_right_bone", head, layout["ear_right"]["pivot"])
rig_image("ear_right", ear_r)
ear_l = node("ear_left_bone", head, layout["ear_left"]["pivot"])
rig_image("ear_left", ear_l)
body = node("body_bone", root, layout["body"]["pivot"])
rig_image("body", body)
rig_image("neck", root)
leg_r = node("front_leg_right_bone", root, layout["front_leg_right"]["pivot"])
rig_image("front_leg_right", leg_r)
leg_l = node("front_leg_left_bone", root, layout["front_leg_left"]["pivot"])
rig_image("front_leg_left", leg_l)
rig_image("back_paw_right", root)
rig_image("back_paw_left", root)
tail = node("tail_bone", root, layout["tail"]["pivot"])
rig_image("tail", tail)

# Flatten (artboard is id 0).
components: list[Component] = []


def flatten(c: Component) -> None:
    components.append(c)
    c.id = len(components)
    for ch in c.children:
        flatten(ch)


flatten(root)
by_name = {c.name: c for c in components}

# Rest pose (local) values for animated properties.
REST = {}
for c in components:
    px, py = c.pivot
    if c.parent:
        lx, ly = px - c.parent.pivot[0], py - c.parent.pivot[1]
    else:
        lx, ly = px, py
    REST[(c.name, K_X)] = lx
    REST[(c.name, K_Y)] = ly
    REST[(c.name, K_ROT)] = 0.0
    REST[(c.name, K_SX)] = 1.0
    REST[(c.name, K_SY)] = 1.0
    REST[(c.name, K_OPACITY)] = c.opacity


# ---------------------------------------------------------------------------
# Animation helpers.
# ---------------------------------------------------------------------------
class Anim:
    def __init__(self, name: str, seconds: float, loop: bool = True):
        self.name = name
        self.frames = round(seconds * FPS)
        self.loop = loop
        # (component, property) -> list of (frame, value, interpolation)
        self.tracks: dict[tuple[str, int], list[tuple[int, float, int]]] = {}

    def key(self, comp: str, prop: int, frame: int, value: float, interp=LINEAR):
        self.tracks.setdefault((comp, prop), []).append((frame, value, interp))

    def const(self, comp: str, prop: int, value: float | None = None):
        if value is None:
            value = REST[(comp, prop)]
        self.key(comp, prop, 0, value, HOLD)

    def wave(self, comp, prop, amp, cycles=1, phase=0.0, offset=0.0, step=3,
             shape=math.sin):
        """Seamless periodic motion around the rest value."""
        base = REST[(comp, prop)] + offset
        for f in range(0, self.frames + 1, step):
            t = f / self.frames
            v = base + amp * shape(2 * math.pi * (cycles * t + phase))
            self.key(comp, prop, min(f, self.frames), v)
        if self.frames % step:
            t = 1.0
            self.key(comp, prop, self.frames,
                     base + amp * shape(2 * math.pi * (cycles * t + phase)))

    def curve(self, comp, prop, points, relative=True):
        """points: list of (seconds, value); relative to rest when relative."""
        base = REST[(comp, prop)] if relative else 0.0
        for sec, v in points:
            self.key(comp, prop, min(self.frames, round(sec * FPS)), base + v)


def bounce(x: float) -> float:
    """|sin| hop profile scaled to -1..1 period like sin (0 at start)."""
    return abs(math.sin(x / 2))


# Face layer sets --------------------------------------------------------------
EYES_OPEN = ["iris_left", "iris_right", "pupil_left", "pupil_right",
             "highlight_left", "highlight_right"]
EYELIDS = ["eyelid_left", "eyelid_right"]
EYES_CLOSED = ["eyes_closed_left", "eyes_closed_right"]
EYES_HAPPY = ["eyes_happy_left", "eyes_happy_right"]
MOUTHS = ["mouth_neutral", "mouth_happy", "mouth_excited", "mouth_surprised",
          "mouth_yawn", "mouth_lick"]
EYE_LAYERS = EYES_OPEN + EYELIDS + EYES_CLOSED + EYES_HAPPY


def face_opacity(anim: Anim, eyes: str, mouth: str, frame: int = 0,
                 interp=HOLD, include_mouth=True):
    on = {
        "open": EYES_OPEN,
        "drowsy": EYES_OPEN + EYELIDS,
        "closed": EYES_CLOSED,
        "happy": EYES_HAPPY,
    }[eyes]
    for n in EYE_LAYERS:
        anim.key(n, K_OPACITY, frame, 1.0 if n in on else 0.0, interp)
    if include_mouth:
        for n in MOUTHS:
            anim.key(n, K_OPACITY, frame, 1.0 if n == mouth else 0.0, interp)


def pupils(anim: Anim, sx: float, frame: int = 0):
    for n in ("pupil_left", "pupil_right"):
        anim.key(n, K_SX, frame, sx, HOLD)


def blink(anim: Anim, at: float, base_eyes: str, mouth: str):
    f = round(at * FPS)
    face_opacity(anim, "closed", mouth, f)
    face_opacity(anim, base_eyes, mouth, f + 7)


# ---------------------------------------------------------------------------
# Mood animations (face only).
# ---------------------------------------------------------------------------
def mood_anim(name, eyes, mouth, pupil_sx, blinks):
    m = Anim(name, 4.0)
    face_opacity(m, eyes, mouth, 0)
    pupils(m, pupil_sx)
    for t in blinks:
        blink(m, t, eyes, mouth)
    return m


mood_sleepy = mood_anim("mood_sleepy", "drowsy", "mouth_neutral", 1.0, [1.6, 3.3])
mood_watchful = mood_anim("mood_watchful", "open", "mouth_neutral", 0.45, [3.2])
mood_content = mood_anim("mood_content", "open", "mouth_neutral", 1.0, [2.4])
mood_joyful = mood_anim("mood_joyful", "happy", "mouth_happy", 1.0, [])

# ---------------------------------------------------------------------------
# Action animations (body; some override the face).
# Every action keys the same motion channels so switching never leaves a
# stale pose behind.
# ---------------------------------------------------------------------------
MOTION = [
    ("root", K_Y), ("root", K_ROT), ("root", K_SX), ("root", K_SY),
    ("body_bone", K_SY), ("head_bone", K_Y), ("head_bone", K_ROT),
    ("tail_bone", K_ROT), ("ear_left_bone", K_ROT), ("ear_right_bone", K_ROT),
    ("front_leg_left_bone", K_ROT), ("front_leg_right_bone", K_ROT),
    ("front_leg_left_bone", K_Y), ("front_leg_right_bone", K_Y),
    ("fx_zzz", K_OPACITY), ("fx_zzz", K_Y),
]


def fill_motion(anim: Anim):
    for comp, prop in MOTION:
        if (comp, prop) not in anim.tracks:
            anim.const(comp, prop)


def breathe(anim: Anim, cycles: int, amount: float = 0.018):
    anim.wave("body_bone", K_SY, amount, cycles, phase=0.75, offset=amount)
    anim.wave("head_bone", K_Y, -amount * 60, cycles, phase=0.75, offset=0)


def ear_twitch(anim: Anim, ear: str, at: float, amount: float):
    anim.curve(ear, K_ROT, [(0, 0), (at, 0), (at + 0.07, amount),
                            (at + 0.16, 0), (at + 0.24, amount * 0.6),
                            (at + 0.34, 0), (anim.frames / FPS, 0)])


act_idle = Anim("action_idle", 4.0)
breathe(act_idle, 2)
act_idle.wave("tail_bone", K_ROT, 0.10, 1)
act_idle.wave("head_bone", K_ROT, 0.025, 1, phase=0.25)
ear_twitch(act_idle, "ear_left_bone", 2.8, -0.14)
fill_motion(act_idle)

act_walk = Anim("action_walk", 0.8)
hop_h = 26
act_walk.wave("root", K_Y, -hop_h, 2, shape=bounce, step=2)
act_walk.wave("root", K_ROT, 0.045, 1, step=2)
act_walk.wave("root", K_SY, 0.035, 2, phase=0.25, step=2)
act_walk.wave("root", K_SX, -0.025, 2, phase=0.25, step=2)
act_walk.wave("front_leg_left_bone", K_ROT, 0.22, 1, step=2)
act_walk.wave("front_leg_right_bone", K_ROT, 0.22, 1, phase=0.5, step=2)
act_walk.wave("front_leg_left_bone", K_Y, -8, 2, shape=bounce, step=2)
act_walk.wave("front_leg_right_bone", K_Y, -8, 2, phase=0.25, shape=bounce, step=2)
act_walk.wave("tail_bone", K_ROT, 0.22, 2, step=2)
act_walk.wave("head_bone", K_ROT, -0.03, 1, step=2)
act_walk.wave("ear_left_bone", K_ROT, 0.05, 2, phase=0.1, step=2)
act_walk.wave("ear_right_bone", K_ROT, -0.05, 2, phase=0.1, step=2)
fill_motion(act_walk)

act_sit = Anim("action_sit", 6.0)
breathe(act_sit, 2, 0.014)
act_sit.wave("tail_bone", K_ROT, 0.05, 1, offset=-0.06)
act_sit.wave("head_bone", K_ROT, 0.05, 1, phase=0.1)
ear_twitch(act_sit, "ear_right_bone", 4.1, 0.12)
fill_motion(act_sit)

act_sleep = Anim("action_sleep", 4.0)
act_sleep.wave("body_bone", K_SY, 0.028, 1, phase=0.75, offset=0.028)
act_sleep.curve("head_bone", K_Y, [(0, 14), (4, 14)])
act_sleep.wave("head_bone", K_ROT, 0.02, 1, offset=0.07)
act_sleep.wave("root", K_SY, 0.0, 1, offset=-0.03)
act_sleep.const("tail_bone", K_ROT, -0.08)
act_sleep.curve("fx_zzz", K_OPACITY, [(0, 0), (0.6, 1), (2.8, 1), (3.6, 0), (4, 0)],
                relative=False)
act_sleep.curve("fx_zzz", K_Y, [(0, 20), (3.6, -40), (4, -40)])
face_opacity(act_sleep, "closed", "mouth_neutral")
pupils(act_sleep, 1.0)
fill_motion(act_sleep)

act_groom = Anim("action_groom", 2.4)
act_groom.wave("head_bone", K_ROT, 0.07, 2, offset=0.08)
act_groom.wave("head_bone", K_Y, 5, 4, offset=10)
act_groom.wave("front_leg_right_bone", K_Y, -12, 2, offset=-30)
act_groom.wave("front_leg_right_bone", K_ROT, 0.08, 2, offset=-0.12)
breathe(act_groom, 1, 0.012)
act_groom.wave("tail_bone", K_ROT, 0.08, 1)
face_opacity(act_groom, "happy", "mouth_lick")
pupils(act_groom, 1.0)
for i in range(4):
    t = i * 0.6
    f0, f1 = round(t * FPS), round((t + 0.3) * FPS)
    act_groom.key("mouth_lick", K_OPACITY, f0, 1.0, HOLD)
    act_groom.key("mouth_neutral", K_OPACITY, f0, 0.0, HOLD)
    act_groom.key("mouth_lick", K_OPACITY, f1, 0.0, HOLD)
    act_groom.key("mouth_neutral", K_OPACITY, f1, 1.0, HOLD)
fill_motion(act_groom)

act_stretch = Anim("action_stretch", 2.6)
act_stretch.curve("root", K_SY, [(0, 0), (0.7, 0.07), (1.8, 0.07), (2.3, 0), (2.6, 0)])
act_stretch.curve("root", K_SX, [(0, 0), (0.7, -0.04), (1.8, -0.04), (2.3, 0), (2.6, 0)])
act_stretch.curve("head_bone", K_Y, [(0, 0), (0.7, -14), (1.8, -14), (2.3, 0), (2.6, 0)])
act_stretch.curve("head_bone", K_ROT, [(0, 0), (0.7, -0.06), (1.8, -0.06), (2.3, 0), (2.6, 0)])
act_stretch.curve("front_leg_left_bone", K_ROT, [(0, 0), (0.7, 0.12), (1.8, 0.12), (2.3, 0), (2.6, 0)])
act_stretch.curve("front_leg_right_bone", K_ROT, [(0, 0), (0.7, -0.12), (1.8, -0.12), (2.3, 0), (2.6, 0)])
act_stretch.curve("ear_left_bone", K_ROT, [(0, 0), (0.7, -0.12), (1.8, -0.12), (2.3, 0), (2.6, 0)])
act_stretch.curve("ear_right_bone", K_ROT, [(0, 0), (0.7, 0.12), (1.8, 0.12), (2.3, 0), (2.6, 0)])
act_stretch.curve("tail_bone", K_ROT, [(0, 0), (0.7, 0.25), (1.8, 0.2), (2.3, 0), (2.6, 0)])
face_opacity(act_stretch, "open", "mouth_neutral", 0)
face_opacity(act_stretch, "closed", "mouth_yawn", round(0.5 * FPS))
face_opacity(act_stretch, "open", "mouth_neutral", round(2.0 * FPS))
pupils(act_stretch, 1.0)
fill_motion(act_stretch)

# ---------------------------------------------------------------------------
# Hop (one shot). The den already lifts the familiar; this adds the squash,
# stretch and the excited face.
# ---------------------------------------------------------------------------
act_hop = Anim("hop", 0.55, loop=False)
act_hop.curve("root", K_SY, [(0, 0), (0.08, -0.10), (0.2, 0.08), (0.38, 0.02), (0.46, -0.07), (0.55, 0)])
act_hop.curve("root", K_SX, [(0, 0), (0.08, 0.08), (0.2, -0.05), (0.38, 0), (0.46, 0.05), (0.55, 0)])
act_hop.curve("root", K_Y, [(0, 0), (0.08, 0), (0.24, -22), (0.4, 0), (0.55, 0)])
act_hop.curve("ear_left_bone", K_ROT, [(0, 0), (0.2, -0.15), (0.46, 0.05), (0.55, 0)])
act_hop.curve("ear_right_bone", K_ROT, [(0, 0), (0.2, 0.15), (0.46, -0.05), (0.55, 0)])
act_hop.curve("tail_bone", K_ROT, [(0, 0), (0.2, 0.3), (0.46, -0.1), (0.55, 0)])
for n in MOUTHS:
    act_hop.key(n, K_OPACITY, 0, 1.0 if n == "mouth_excited" else 0.0, HOLD)
    act_hop.key(n, K_OPACITY, act_hop.frames, 1.0 if n == "mouth_excited" else 0.0, HOLD)

ANIMS = [mood_sleepy, mood_watchful, mood_content, mood_joyful,
         act_idle, act_walk, act_sit, act_sleep, act_groom, act_stretch,
         act_hop]
ANIM_INDEX = {an.name: i for i, an in enumerate(ANIMS)}

# ---------------------------------------------------------------------------
# Write the file.
# ---------------------------------------------------------------------------
w = Writer()
w.buf += b"RIVE"
w.varuint(7)  # major
w.varuint(0)  # minor
w.varuint(0)  # file id
w.varuint(0)  # empty property table of contents: every key is known to 7.0

w.obj(T_BACKBOARD)
for i, (name, data, iw, ih) in enumerate(assets):
    w.obj(T_IMAGE_ASSET, assetName=name, fileAssetId=i, assetWidth=iw,
          assetHeight=ih)
    w.obj(T_FILE_ASSET_CONTENTS, bytes=data)

w.obj(T_ARTBOARD, name="Cat", width=ARTBOARD, height=ARTBOARD, clip=False,
      defaultStateMachineId=0)
for c in components:
    parent_id = c.parent.id if c.parent else 0
    props = dict(
        name=c.name,
        parentId=parent_id,
        x=REST[(c.name, K_X)],
        y=REST[(c.name, K_Y)],
    )
    if c.opacity != 1.0:
        props["opacity"] = c.opacity
    if c.kind == "node":
        w.obj(T_NODE, **props)
    else:
        w.obj(T_IMAGE, **props, imageAssetId=c.asset,
              imageOriginX=c.origin[0], imageOriginY=c.origin[1])

for an in ANIMS:
    w.obj(T_LINEAR_ANIMATION, animationName=an.name, fps=FPS,
          duration=an.frames, loopValue=LOOP if an.loop else ONE_SHOT)
    by_comp: dict[str, list[int]] = {}
    for comp, prop in an.tracks:
        by_comp.setdefault(comp, []).append(prop)
    for comp, props in by_comp.items():
        w.obj(T_KEYED_OBJECT, objectId=by_name[comp].id)
        for prop in props:
            w.obj(T_KEYED_PROPERTY, propertyKey=prop)
            frames = {}
            for f, v, interp in an.tracks[(comp, prop)]:
                frames[f] = (v, interp)  # last write per frame wins
            for f in sorted(frames):
                v, interp = frames[f]
                w.obj(T_KEYFRAME_DOUBLE, frame=f, value=v,
                      interpolationType=interp)

# State machine --------------------------------------------------------------
INPUT_ACTION, INPUT_MOOD, INPUT_HOP = 0, 1, 2
w.obj(T_STATE_MACHINE, animationName="Familiar")
w.obj(T_SM_NUMBER, smName="action", numberValue=0)
w.obj(T_SM_NUMBER, smName="mood", numberValue=2)
w.obj(T_SM_TRIGGER, smName="hop")

# Layer states are indexed in the order written: 0 entry, 1 any, 2 exit, 3+.
MIX_MS = 250


def numeric_layer(name: str, input_id: int, states: list[str], default: int):
    w.obj(T_SM_LAYER, smName=name)
    w.obj(T_ENTRY_STATE)
    w.obj(T_STATE_TRANSITION, stateToId=3 + default)
    w.obj(T_ANY_STATE)
    for i, _ in enumerate(states):
        w.obj(T_STATE_TRANSITION, stateToId=3 + i, transitionDuration=MIX_MS)
        w.obj(T_NUMBER_CONDITION, inputId=input_id, opValue=OP_EQUAL,
              conditionValue=float(i))
    w.obj(T_EXIT_STATE)
    for s in states:
        w.obj(T_ANIMATION_STATE, animationId=ANIM_INDEX[s])


numeric_layer("Mood", INPUT_MOOD,
              ["mood_sleepy", "mood_watchful", "mood_content", "mood_joyful"],
              default=2)
numeric_layer("Action", INPUT_ACTION,
              ["action_idle", "action_walk", "action_sit", "action_sleep",
               "action_groom", "action_stretch"],
              default=0)

w.obj(T_SM_LAYER, smName="Hop")
w.obj(T_ENTRY_STATE)
w.obj(T_ANY_STATE)
w.obj(T_STATE_TRANSITION, stateToId=3)
w.obj(T_TRIGGER_CONDITION, inputId=INPUT_HOP)
w.obj(T_EXIT_STATE)
w.obj(T_ANIMATION_STATE, animationId=ANIM_INDEX["hop"])
w.obj(T_STATE_TRANSITION, stateToId=2,
      transitionFlags=EXIT_TIME | EXIT_TIME_PERCENT, exitTime=100)

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_bytes(bytes(w.buf))
print(f"wrote {OUT.relative_to(REPO)} ({len(w.buf) / 1024:.0f} KiB, "
      f"{len(assets)} images, {len(components)} components, "
      f"{len(ANIMS)} animations)")
