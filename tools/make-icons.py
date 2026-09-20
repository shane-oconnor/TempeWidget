#!/usr/bin/env python3
"""Render TempeWidget's thermometer launcher icon at every size a device wants.

Run from the repo root: python3 tools/make-icons.py
Requires Pillow. Regenerate after changing the geometry below, then
rebuild; monkeyc warns if any icon is the wrong size for its device.

Geometry was measured from the original 40x40 Therm2d.png and is expressed
in that same 40-unit coordinate space, so the 40x40 output is a faithful
reproduction of the original and every other size is a clean render rather
than an upscale.
"""

from PIL import Image, ImageDraw

WHITE = (253, 252, 253)
RED = (255, 0, 0)

# All measurements in the original's 40x40 space.
CX = 20.0
TUBE_OUTER_HALF = 5.0        # x 15..25
TUBE_WALL = 2.0              # bore is x 17..23
CAP_CY = 5.0                 # rounded cap centre; top of icon is y=0
BULB_CY = 31.0
BULB_OUTER_R = 9.0           # x 11..29, bottom y=40
BULB_RING = 3.0              # inner glass radius 6.0
MERC_HALF = 2.0              # column x 18..22
MERC_TOP = 13.0            # centre of the rounded top; column starts at y=11
MERC_BULB_R = 4.5
TUBE_BOTTOM = 30.0           # tube meets the bulb
# Tick centres and thickness recovered from the original by alpha centre-of-
# mass per tick: centres 5.31/8.34/11.34/14.37/17.40, total coverage ~0.7px.
TICK_X0, TICK_X1 = 8.0, 13.8
TICK_YS = (5.35, 8.35, 11.35, 14.35, 17.35)
TICK_H = 0.7
TICK_ALPHA = 255

SS = 16                      # supersampling factor


def render(size):
    s = size * SS / 40.0     # scale from the 40-unit space to supersampled px
    n = size * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def rect(x0, y0, x1, y1, fill):
        d.rectangle([x0 * s, y0 * s, x1 * s - 1, y1 * s - 1], fill=fill)

    def disc(cx, cy, r, fill):
        d.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s - 1, (cy + r) * s - 1],
                  fill=fill)

    # --- glass, drawn solid then hollowed out -------------------------------
    glass = (*WHITE, 255)
    disc(CX, CAP_CY, TUBE_OUTER_HALF, glass)                         # rounded cap
    rect(CX - TUBE_OUTER_HALF, CAP_CY, CX + TUBE_OUTER_HALF, TUBE_BOTTOM, glass)
    disc(CX, BULB_CY, BULB_OUTER_R, glass)                           # bulb

    hole = (0, 0, 0, 0)
    bore = TUBE_OUTER_HALF - TUBE_WALL
    disc(CX, CAP_CY, bore, hole)
    rect(CX - bore, CAP_CY, CX + bore, BULB_CY, hole)
    disc(CX, BULB_CY, BULB_OUTER_R - BULB_RING, hole)

    # --- mercury ------------------------------------------------------------
    rect(CX - MERC_HALF, MERC_TOP, CX + MERC_HALF, BULB_CY, (*RED, 255))
    disc(CX, MERC_TOP, MERC_HALF, (*RED, 255))                       # rounded top
    disc(CX, BULB_CY, MERC_BULB_R, (*RED, 255))

    # --- graduation ticks ---------------------------------------------------
    for ty in TICK_YS:
        rect(TICK_X0, ty - TICK_H / 2, TICK_X1, ty + TICK_H / 2,
             (*WHITE, TICK_ALPHA))

    return img.resize((size, size), Image.LANCZOS)


# Products whose launcher icon is not 40x40, grouped by the size they want.
# The other 29 products in manifest.xml use the 40x40 original in resources/.
# Read from each device's compiler.json; re-check when adding a product.
SIZES = {
    26: ["instinctcrossover"],
    35: ["fr55"],
    54: ["instinct2s"],
    60: ["epix2", "epix2pro42mm", "epix2pro47mm", "epix2pro51mm",
         "fr265", "marq2", "marq2aviator",
         "fenix843mm", "fenix943mm", "fenix9pro43mm"],
    62: ["descentg1", "instinct2"],
    65: ["fenix9pro51mm", "fr965",
         "fenix847mm", "fenix8pro47mm", "fenix947mm", "fenix9pro47mm", "fr970"],
    70: ["venu2"],
}


def main():
    import os
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for size in sorted(SIZES):
        d = os.path.join(root, f"resources-icon{size}", "drawables")
        os.makedirs(d, exist_ok=True)
        render(size).save(os.path.join(d, "Therm2d.png"))
        with open(os.path.join(d, "drawables.xml"), "w") as fh:
            fh.write('<drawables>\n'
                     '    <bitmap id="LauncherIcon" filename="Therm2d.png" />\n'
                     '</drawables>\n')
        print(f"wrote resources-icon{size}/drawables/Therm2d.png ({size}x{size})")
    print("\nmonkey.jungle maps each product to its folder via resourcePath.")


if __name__ == "__main__":
    main()
