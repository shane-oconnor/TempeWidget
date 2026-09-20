# TempeWidget

[![validate](https://github.com/shane-oconnor/TempeWidget/actions/workflows/validate.yml/badge.svg)](https://github.com/shane-oconnor/TempeWidget/actions/workflows/validate.yml)

A Garmin Connect IQ widget that shows temperature from up to three sources at
once — ANT+ [tempe](https://www.garmin.com/en-US/p/107335) sensors, the watch's
own internal sensor, or a tempe paired over Bluetooth — each with its own
label, calibration offset, and min/max range since the reading was first seen.

Written in Monkey C. Available on the
[Connect IQ Store](https://apps.garmin.com/), and buildable from source with
the Connect IQ SDK.

## Display

Each source gets its own page; swipe up/down or press next/previous to move
between them. A glance view shows all three at once in the widget carousel.

| Shown | Notes |
|---|---|
| Current temperature | °C or °F, following the watch's system units |
| Min / Max | Lowest and highest seen since the reading was cached |
| Battery | ANT+ sensors only; flagged when `LOW` or `CRITICAL` |
| Age | How long ago the reading arrived |

Readings are cached in `Application.Storage`, so they survive the widget being
backgrounded. A reading older than the configured timeout is discarded.

## Settings

Configured per-device in the Garmin Connect app under the widget's settings.

| Setting | Default | Meaning |
|---|---|---|
| `Tempe 0/1/2 ID` | `0`, `0`, `-1` | Which sensor feeds this slot — see below |
| `Tempe 0/1/2 Name` | `Tempe1`, `Tempe2`, `Internal` | Label drawn above the reading (max 12 chars) |
| `Tempe 0/1/2 Offset °C` | `0.0` | Calibration offset, −25 to +25, applied at display time only |
| `Cache/Timeout period` | `1200` | Seconds before a reading is considered stale and cleared |
| `White Background` | off | Inverts the colour scheme |
| `Show Tempe Battery Level` | on | Draws the battery indicator |
| `Debug Mode` | off | Enables diagnostic output in the simulator |

The ID field selects the source for that slot:

| ID | Source |
|---|---|
| `-1` | The watch's internal temperature sensor |
| `-2` | A tempe paired over Bluetooth |
| `0` | Any unpaired ANT+ tempe (auto-discover) |
| `> 0` | A specific ANT+ device number |

Slots with a specific device number are claimed before wildcard slots, so a
`0` slot cannot steal a sensor that another slot is pinned to.

> **Known issue:** the `Number of Tempe` setting is present in the settings
> menu but is not read by the app — all three slots are always active. See
> [#2](https://github.com/shane-oconnor/TempeWidget/issues/2).

Changing a setting currently takes effect when the widget next starts, not
immediately.

## Supported devices

43 products, listed in [`manifest.xml`](manifest.xml): fēnix 6/7/8-era and
fēnix 9 Pro, epix 2 and epix Pro, MARQ and MARQ 2, Forerunner 55/255/265/745/
945/955/965, Instinct 2 / Crossover, and Descent G1.

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
- `@Strings.*` references that resolve to nothing, and unused strings
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

## Layout

| Path | Role |
|---|---|
| `source/TempeWidgetApp.mc` | App lifecycle shell |
| `source/TempeWidgetState.mc` | Model — global state, sensor init, 5s timer, `TempItem` slots |
| `source/TempeWidgetView.mc` | Full-screen view; all geometry derived from `dc` dimensions |
| `source/TempeWidgetGlanceView.mc` | Compact glance view |
| `source/TempeWidgetDelegate.mc` | Input and page navigation |
| `source/TempeWidgetSensor.mc` | ANT+ channel management, isolated from the UI |
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
