# TempeWidget — CLAUDE.md

## Project Purpose

TempeWidget is a **Garmin Connect IQ widget** written in Monkey C. It displays temperature data from up to 3 configurable sources simultaneously:

- **ANT+ Tempe sensors** — wireless Garmin temperature sensors (up to 3, with min/max ranges and battery status)
- **Internal device sensor** — the watch's built-in temperature sensor
- **Paired Tempe** — a Tempe sensor paired via Bluetooth

Users configure which sources to monitor and their labels/offsets in the app settings. The widget supports both Celsius and Fahrenheit and provides a compact glance view for quick access.

---

## Architecture

The project follows an MVC pattern across 6 source files in `source/`:

| File | Role |
|---|---|
| `TempeWidgetApp.mc` | App lifecycle shell — creates State and View, nothing else |
| `TempeWidgetState.mc` | **Model** — holds global state, initializes sensors, runs the 5s timer, manages `TempItem` objects |
| `TempeWidgetView.mc` | **Main view** — full-screen rendering of current/min/max temp + battery indicator |
| `TempeWidgetGlanceView.mc` | **Glance view** — compact 3-column layout for the widget glance panel |
| `TempeWidgetDelegate.mc` | **Controller** — swipe/button input, page navigation |
| `TempeWidgetSensor.mc` | ANT+ channel management — fully isolated from UI; communicates back via `updateTempeTemp()` |
| `TempeWidgetCommon.mc` | Shared constants (colors, fonts), no logic |

**Resource files:**
- `resources/TempWidgetApResources.xml` — app properties (settings schema + defaults)
- `resources/strings/strings.xml` — localized strings and settings menu titles
- `resources/layouts/layout.xml` — minimal layout (most drawing is procedural in the view)
- `manifest.xml` — app metadata, supported devices list, required permissions

---

## Key Architecture Decisions

### TempItem slots
There are always exactly 3 temperature slots (`cTempItem = 3` in Common.mc). Each is a `TempItem` instance holding: device ID, label, offset, current temp, min/max, battery status, and last-seen timestamp. The number of visible slots can be reduced via the `TempeCount` setting, which `State.updateSettings()` clamps to 1–3 and exposes as `State.cTempe`. Slots at or above `cTempe` are not polled, get no ANT channel, and are skipped by the view and by page navigation — but `checkTimeout()` still runs over all 3, so a hidden slot's cached reading still expires.

### Device ID scheme
| ID | Meaning |
|---|---|
| `-1` | Internal device sensor |
| `-2` | Paired Tempe (via BLE) |
| `0` | Any ANT+ Tempe (auto-discover) |
| `>0` | Specific ANT+ device number |

### Two-pass sensor initialization
When creating `TempeWidgetSensor` objects, specific device IDs (`>0`) are initialized first. Wildcard (`0`) IDs are initialized second. This prevents a wildcard sensor from claiming a device that should be paired to a specific slot.

### Live settings
`TempeWidgetApp.onSettingsChanged()` calls `State.updateSettings()`, so a setting changed in the Connect app takes effect without relaunching the widget. `updateSettings()` re-reads every property, then releases **all** ANT channels and reopens only the active slots — that is what makes a changed device ID take hold. Any new setting read inside `updateSettings()` is live for free; one read anywhere else is not.

### Data persistence
`Application.Storage` caches each slot's last temperature, min/max, battery status, and timestamp. Data survives the widget being backgrounded between timer ticks.

### Expiry system
`checkTimeout()` runs every 5 seconds. At 50% of timeout (default 1200s), the slot is marked "expiring" and rendered with reduced opacity. At 100%, data is cleared. This surfaces stale data visually without hard-cutting it.

### Temperature units
Temperatures are stored internally in **0.01°C units** (integer arithmetic). ANT+ min/max payloads use **0.1°C units**. The temperature offset (`tos`) is a float in °C and is applied at render time, not storage time. Unit conversion (°C → °F) also happens at render time only.

---

## Coding Conventions

### Variable prefixes (Hungarian-style)
| Prefix | Type | Example |
|---|---|---|
| `f` | Boolean | `fDbg`, `fWhiteBG`, `fExpiring` |
| `i` | Integer | `iTemp`, `iMin`, `iMax` |
| `rg` | Array | `rgTemp` |
| `tm` | Timestamp | `tmLast`, `tmOut` |
| `str` | String-returning function | `strTemp()`, `strTime()` |
| `pg` | ANT page number | `pg` |
| `c` | Count constant | `cTempItem` |

### Constants (TempeWidgetCommon.mc)
- Colors: `ClrTrans`, `ClrWhite`, `ClrBlack`, `ClrDkGray`, `ClrLtGray`, `ClrYellow`

Always use these named constants rather than raw hex values for colors.

There is no font-index constant. Both views pick a font at render time with `fitFont()` (also in Common.mc), which walks a ladder of `Graphics.FONT_*` values largest-first and returns the biggest that fits the available width — and, where a height is given, the line height too. `fitStr()` clips a string that still overflows at the smallest font in the ladder. Use these rather than naming a font directly, so layouts keep working across the full device matrix.

### Debug logging
All debug output uses `System.println()` gated by the `fDbg` flag (set via the `Dbg` app setting). Never log unconditionally; always wrap in `if (fDbg)`. `State`, `TempItem` and `TempeWidgetSensor` each hold their own `fDbg` copy, threaded down from `State.updateSettings()`, so any of them can gate its own output.

The one exception is a `println` inside a `catch` block: reporting a failure that was actually caught is not debug logging, and hiding it behind a flag the user has switched off is how a real fault goes unnoticed. `tools/validate.py` enforces both halves of this rule.

### Settings
Settings are read in `TempeWidgetState.mc` using `Properties.getValue("KeyName")`. Defaults are defined in `TempWidgetApResources.xml`.

---

## Common Tasks

### Adding a new supported device

1. Open `manifest.xml`
2. Add a `<iq:device id="deviceId"/>` entry in the `<iq:products>` list
3. Check `TempeWidgetView.mc` for any `dc.getWidth()`/`dc.getHeight()` guards — if the new device has an unusual screen size, add a layout adjustment there

### Adding a new app setting

1. Add a `<iq:property>` entry with a default value to `TempWidgetApResources.xml`
2. Add a matching `<setting>` entry to the settings UI section of `TempWidgetApResources.xml`
3. Add a string label to `resources/strings/strings.xml`
4. Read the property in `TempeWidgetState.mc` `updateSettings()` using `getProp()` — not `initialize()`, or the setting will not apply until relaunch
5. Store it as an instance variable on `State` and expose it to the view

### Adding a new display field to TempItem

1. Add the field to the `TempItem` class in `TempeWidgetState.mc`
2. If the data comes from ANT+, populate it in `TempeWidgetSensor.mc` inside `onMessage()` → `parsePayload()`, then call the appropriate update method on the TempItem
3. If it requires persistence, add `Application.Storage` read/write alongside the existing temp/battery storage pattern
4. Render the new field in `TempeWidgetView.mc` `onUpdate()`

### Adding a new sensor type

Follow the `TempeWidgetSensor.mc` pattern:
1. Create a new `.mc` file with a class that sets up an `Ant.GenericChannel`
2. Implement `onMessage(msg)` to handle `MSG_ID_BROADCAST_DATA` and `MSG_ID_CHANNEL_RESPONSE_EVENT`
3. Call back into `TempItem` via a method (not direct field access) when data arrives
4. Instantiate the sensor in `TempeWidgetState.mc` during the appropriate init pass

---

## Debugging

### Enable debug mode
In the Garmin Connect app, open TempeWidget settings and enable **Dbg**. This activates `System.println()` output showing device IDs and ANT channel events.

### Simulator testing
Use the **Garmin Connect IQ SDK Simulator** in VS Code (with the Monkey C extension). To test ANT+ sensors:
- Use the simulator's ANT+ device simulation panel to inject Tempe sensor data
- `System.println()` output appears in the simulator's Application Output log

### Common issues
- **No temperature shown**: Check the device ID setting (0 = any, specific ID = must match sensor). Enable `Dbg` to see which IDs are being searched.
- **Stale data / expiring quickly**: Check the `Timeout` setting (default 1200s). If a sensor stops broadcasting, data will fade at 50% of timeout.
- **Wrong temperature**: The offset (`T0Offset` etc.) is in °C and added at render time. A non-zero offset does not affect stored values.
- **White background rendering issues**: The `fWhiteBG` flag switches `ClrBlack`↔`ClrWhite` for text/background. Any new drawing code must respect this flag.

---

## Permissions Required

Declared in `manifest.xml`:
- `Ant` — ANT+ wireless communication
- `Sensor` — device sensor access (internal temperature)
- `SensorHistory` — historical sensor data

Minimum API level: **3.2.0**
