# TempeWidget

[![validate](https://github.com/shane-oconnor/TempeWidget/actions/workflows/validate.yml/badge.svg)](https://github.com/shane-oconnor/TempeWidget/actions/workflows/validate.yml)

A Garmin Connect IQ widget that shows temperature from up to three sources at
once — ANT+ [tempe](https://www.garmin.com/en-US/p/107335) sensors, the watch's
own internal sensor, or a tempe paired over Bluetooth — each with its own
label, calibration offset, and the tempe's own 24 hour low and high.

Tempes are found automatically: the widget listens for every tempe in range and
binds each one to a slot, so two tempes land on two pages without typing ANT
IDs into the phone. A sensor that is switched off, out of range or not owned
simply has no page.

Written in Monkey C. Available on the
[Connect IQ Store](https://apps.garmin.com/), and buildable from source with
the Connect IQ SDK.

## Display

Each source with a reading gets its own page; swipe up/down or press
next/previous to move between them. The glance shows the first tempe's
temperature with its 24 hour low and high.

| Shown | Notes |
|---|---|
| Current temperature | °C or °F, following the watch's system units; drawn large, in a vector font where the watch has one |
| Low / High | The tempe's own 24 hour range, with a bar showing where the reading sits in it |
| Six hour history | On the internal sensor page, the watch's own temperature record as a line |
| Battery | ANT+ sensors only; flagged when `LOW` or `CRITICAL` |
| Age | How long ago the reading arrived |
| ANT id | Under the label, so two tempes can be told apart |

The label takes a colour from the temperature band (blue through red). Readings
are cached in `Application.Storage`, so they survive the widget being
backgrounded. A reading past half its timeout is dimmed; past the timeout it is
cleared and its page disappears.

Long-press (or the menu button) opens a menu on the watch: a list of which
sensor each slot is bound to, "Forget Tempes" to start the search over, and
toggles for the battery icon and the white background.

## Settings

Configured per-device in the Garmin Connect app under the widget's settings.

| Group | Setting | Default | Meaning |
|---|---|---|---|
| Display | `White background` | off | Inverts the colour scheme |
| Display | `Show Tempe battery` | on | Draws the battery indicator |
| Sensor 1/2/3 | `Name` | `Tempe1`, `Tempe2`, `Internal` | Label drawn above the reading (max 12 chars) |
| Sensor 1/2/3 | `Sensor ID` | `0`, `0`, `-1` | Which sensor feeds this slot — see below |
| Sensor 1/2/3 | `Offset (°C)` | `0.0` | Calibration offset, −25 to +25, applied at display time only |
| Advanced | `Keep a reading for` | 20 minutes | How long a reading stays after the sensor goes quiet |
| Advanced | `Debug mode` | off | Enables diagnostic output in the simulator |

The ID field selects the source for that slot:

| ID | Source |
|---|---|
| `-1` | The watch's internal temperature sensor |
| `-2` | A tempe paired over Bluetooth |
| `0` | Find a tempe automatically |
| `> 0` | A specific ANT+ device number |

A `0` slot is filled by the first tempe the scanner hears that no other slot
already has, and the device number is then written into that slot's ID setting
so the label and offset stay with that physical sensor. Set the ID back to `0`
(or use "Forget Tempes" on the watch) to search again.

Settings take effect while the widget is open.

## Supported devices

96 products, listed in [`manifest.xml`](manifest.xml): the fēnix 6 to 9
lines, epix 2 and epix Pro, MARQ and MARQ 2, Enduro, Forerunner 55 to 965,
Venu 2 to 4, vívoactive 4 and 5, Instinct 2 and 3 / Crossover, Descent and
D2.

Minimum API level **3.2.0**. Requires the `Ant`, `Sensor` and `SensorHistory`
permissions.

## Building

Needs the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) —
**9.2.0 or later** for the fēnix 9 targets — installed through the SDK
Manager, along with the device definitions for whatever you are targeting. An
`<iq:product>` id with no matching device definition installed fails the
*entire* build, not just that target.

```sh
# one device, strict type checking
"$SDK/bin/monkeyc" -o out.prg -f monkey.jungle -y "$DEV_KEY" -d fenix9pro51mm -l 2

# every product in the manifest, both type-check levels, plus the store export
tools/build-matrix.sh
```

`tools/build-matrix.sh` reads the SDK path from `current-sdk.cfg` and the
developer key from `$CIQ_DEV_KEY` (default `~/Documents/VS Code/developer_key`).

## Continuous integration

The device definitions the compiler needs are only downloadable through the
SDK Manager after a Garmin account login, so a hosted runner cannot compile
this project. CI instead runs [`tools/validate.py`](tools/validate.py), which
checks the things the compiler is silent about:

- unresolved merge-conflict markers in tracked files
- XML well-formedness of the manifest and every resource
- duplicate `<iq:product>` ids
- `@Strings.*` and `Rez.Strings.*` references that resolve to nothing, and
  unused strings
- `@Properties.*` settings entries with no matching property
- properties declared and offered in the settings menu that no source file
  reads (keys built by concatenation, like `"T" + i + "ID"`, are matched as
  patterns)
- `System.println` that is not wrapped in `if (fDbg)`

Run it locally the same way CI does:

```sh
python3 tools/validate.py
```

Compile coverage stays a local step — run `tools/build-matrix.sh` before
tagging a release.

## Releasing

`tools/build-matrix.sh` writes `export/TempeWidget.iq`, which is what gets
uploaded to the Connect IQ Store. Build it from a clean tree so the upload
matches the tag.

The Store listing copy — description, release notes, and what is generated
rather than written by hand — is kept in
[`docs/store-listing.md`](docs/store-listing.md), versioned alongside the
release it describes.

Launcher icons are per-device: 41 of the 96 products want 40x40 and use
`resources/drawables/Therm2d.png`; the rest are rendered by
[`tools/make-icons.py`](tools/make-icons.py) into `resources-icon<N>/` and
mapped in `monkey.jungle`. When adding a product, check its
`launcherIcon.width` in that device's `compiler.json` — if it is not 40, add
the id to `SIZES`, rerun the script, and add a `resourcePath` line.

## Layout

| Path | Role |
|---|---|
| `source/TempeWidgetApp.mc` | App lifecycle shell |
| `source/TempeWidgetState.mc` | Model — global state, sensor init, 5s timer, `TempItem` slots |
| `source/TempeWidgetView.mc` | Full-screen view; all geometry derived from `dc` dimensions |
| `source/TempeWidgetGlanceView.mc` | Compact glance view |
| `source/TempeWidgetDelegate.mc` | Input and page navigation |
| `source/TempeWidgetSensor.mc` | ANT+ channel management, isolated from the UI |
| `source/TempeWidgetScanner.mc` | One background-scanning ANT channel that finds every tempe in range |
| `source/TempeWidgetMenuDelegate.mc` | The on-device menu |
| `source/TempeWidgetCommon.mc` | Shared constants and helpers |

Temperatures are stored as integers in 0.01 °C units; ANT+ min/max payloads
arrive in 0.1 °C units. Offsets and °F conversion are applied at render time,
never to the stored value.

[`CLAUDE.md`](CLAUDE.md) documents the conventions in more depth.

## Acknowledgements

Based on the [TempX](https://apps.garmin.com/apps/cd341b2d-aa37-40f9-b5b6-4aff2416e535)
widget by ekutter, with thanks for sharing the code base.

## Licence

[MIT](LICENSE).
