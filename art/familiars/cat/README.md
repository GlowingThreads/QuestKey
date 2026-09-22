# Quest Key — Shadow Cat rig parts

Everything here is cut from the six ChatGPT sheets, trimmed, named, and assembled into a
front-facing sitting cat on a 2048 x 2048 canvas.

## What's in the folder

| Item | What it is |
| --- | --- |
| `shadow_cat_rig.psd` | Every part as a named layer, already positioned and in draw order. Alternate expressions are included as hidden layers. Start here. |
| `layers_fullcanvas/` | The same layers as 2048 x 2048 PNGs. Stack them at the same position and they line up exactly. Numbered in draw order (00 = back). |
| `parts/` | Each part cropped tight at full resolution, plus the props and effects (treat, yarn, heart, sparkles, Zzz). |
| `layout.json` | Position, scale, size, draw order, default visibility and pivot point for every part. |
| `preview_assembled.png` | The default pose. |
| `preview_pivots.png` | Where each bone should rotate from. |
| `preview_expressions.png` | All eight expressions built from the layers. |

**Left/right** always means the side of the *screen* the part sits on, not the cat's own left.

## Changes made while assembling

- **Neck:** the neck stub was split off the head into its own `neck` layer, placed *behind* the body. Left on the head, it showed as a collar across the chest. It still fills the gap when the head tilts.
- **Legs:** the front legs and back paws sit *behind* the body, so only the paws show below it. Their long tops are hidden and can swing without a gap.

## Importing into Rive

1. Import `shadow_cat_rig.psd` (drag it onto the Rive canvas). Layers keep their names, positions and order.
2. If your Rive version won't take the PSD, import the PNGs from `layers_fullcanvas/` instead. Drop them all at 0,0 and they assemble themselves.

## Rigging suggestions

- **Bones:** body root at the `body` pivot, head bone at the `head` pivot (ears, eyes, nose, mouths and whiskers parented to it), one bone per ear, one per front leg, and a chain of 3–4 bones along the tail.
- **Look-at:** clip each pupil to its iris and move the pupils with one number input (-1…1). Leave the highlights where they are, since reflections don't follow the gaze.
- **Drowsy:** lower the `eyelid_*` layers over the eyes (clip them to the iris).
- **Full blink and sleep:** hide the iris, pupil and highlight layers and show `eyes_closed_*` for a frame or two.
- **Expressions:** each mouth and eye state is its own layer. Toggle visibility (or opacity 0/1) from the state machine.
