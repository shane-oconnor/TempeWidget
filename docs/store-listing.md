# Connect IQ Store listing — draft copy for v1.0.0

App: **Tempe Widget** by ShaneO
Listing: https://apps.garmin.com/apps/194a50be-400a-432a-9efa-402b4b7cae18
Currently live: version "0.68 Added EPIX", released 3 June 2024.
4.4 from 19 reviews, 1K+ downloads.

Nothing below has been submitted. These are drafts for review.

Kept in the repo so the copy is versioned alongside the release it describes.
Update it when the listing changes, and note what actually went live.

---

## 1. Version field

The Store version field is free text. It currently reads `0.68 Added EPIX`.

```
1.0.0 Added fēnix 9 Pro
```

---

## 2. Description (full replacement)

```
This widget allows you to quickly display the current temperature, plus the
24hr min and max, from up to three sources at the same time - Garmin tempe
sensors, your watch's built in temperature sensor, or a tempe paired over
Bluetooth. Swipe up and down to move between them, or use the glance view to
see all three together.

Each of the three slots is configured separately, with its own name, ID and
calibration offset.

ID - By default this should be "0", which means this will connect to the first
available Tempe Sensor. If you want to connect to a specific Tempe Sensor then
add the ID number here. The easiest way to get that number is to pair the tempe
and see what ID is given. My Tempe has a 6 digit number. Use -1 for your
watch's internal temperature sensor, or -2 for a tempe paired over Bluetooth.

Please note the 24hr min and max are reported by the tempe sensor itself, so
they are only available on tempe slots. The internal watch sensor gives the
current temperature only and will show "--" for min and max. Some watches don't
give access to the internal sensor or to a paired tempe at all - where the watch
doesn't provide it you will see "--". Sorry, I can't override this.

Name - the label shown above the reading, up to 12 characters. Handy if you have
one tempe outside and one in the shed.

Timeout - how long the widget retains a value when it isn't getting updated.
Once the timeout passes the reading is cleared.

Tempe C Offset - use this setting to calibrate your tempe. Allows you to enter a
positive or negative temperature in Celsius into this field. This will adjust
the current temperature and the prior 24 hr Max and Min Temperatures. I added
this as I have two tempe devices, which read about 0.5 C different, even though
they are positioned next to each other. If you are using fahrenheit, then you
will need to convert F to C before entering the value.

Show Tempe Battery - this displays an image of the Tempe battery. Once enabled
this icon can take up to 5 minutes for the Tempe to publish the battery status.
I have tested with various batteries, and I'm not sure how accurate the battery
status is on the tempe. I seem to get a status of BATT_STATUS_OK = 3,
irrespective of whether the battery is new or old.

White Background - switches the display to dark text on a white background.

Debug - if you set this to true, the current ID will be shown on the full widget
page with each temperature.

The source code is on GitHub at https://github.com/shane-oconnor/TempeWidget -
issues and suggestions are welcome there.

Based on the TempX widget, with credit to ekutter, thanks for sharing the code
base.

Tested as working on fēnix 9 Pro 51mm and 955 Solar, other testing performed on
the Connect IQ simulator.
```

### What changed and why

- Leads with **three sources**, which the old text never actually said — it read
  as a single-sensor widget.
- Documents **-1 and -2** for the ID field. The settings menu explains these but
  the listing never did.
- Documents the **Name** and **White Background** settings, both missing before.
- Adds the **min/max caveat**. Verified in the code: for a tempe slot the min and
  max come from the sensor's own page-1 broadcast, but for internal and paired
  slots they are written as null, so those legitimately show `--`. This is the
  single most likely source of "it's broken" reviews.
- Fixes **"emitter" to "ekutter"**, which is the actual developer name on the
  TempX listing. Check you're happy with this — it's your credit line.
- Adds the GitHub link in the body. The listing already has a Source Code link
  pointing there, but it's easy to miss.

---

## 3. What's New

This field holds the whole changelog, so the new entry goes on top and the rest
stays as it is.

```
1.0.0 Added fēnix 9 Pro (51mm)

- Fixed sub-zero temperatures reading slightly too warm. Below freezing the
  current reading was out by 0.01 C and the 24hr min and max by 0.1 C
- Fixed a crash that could occur every few seconds on watches with no stored
  temperature history, for example after a reboot
- Fixed cached readings being timed against a clock that resets when the watch
  restarts, so values could expire early or linger
- Fixed the temperature offset showing "--" instead of applying the offset
- Fixed the battery icon ignoring the White Background setting
- A critical tempe battery level is now flagged, not just a low one
- Rebuilt the full screen layout so it scales to the watch screen instead of
  being fixed to one size
- Sharper launcher icon on watches that ask for a larger one, instead of a
  scaled up 40x40
- Source code published at https://github.com/shane-oconnor/TempeWidget

After updating, temperatures may show "--" once on the first launch while the
old cache is cleared. Readings come back on the next sensor update.

0.68 Added Garmin Epix models

0.67 Changed Offset max from 5 to 25

0.66 Added Fenix 7 Pro models

0.65 Fixed white background bug.

0.64 Added Temperature offset variable to settings.

0.63 Added support for round sub screens on Instinct Models

0.62 Swipe up and down directions added for scrolling between screens

0.6 Update to allow up to 3 tempe to be connected or 2 tempe and 1 internal temperature.

0.5 Added Battery Status Icon

0.41 Device List Updated

0.4 Additional devices attached

0.3 Additional devices attached

0.2 Fixed bug - 24Min and 24Max value clear after the timeout period now

0.1 Initial Release
```

---

## 4. Compatible devices — nothing to write

Garmin generates this list from the product ids in the uploaded `.iq` file and
expands each into its marketing names, including the quatix and tactix variants
that share hardware. The live listing shows 60 rows generated from the 42
products in 0.68.

So this is **not** copy to update. Uploading the new `.iq` (43 products) adds the
fēnix 9 Pro rows by itself. Nothing to do by hand.

---

## 5. Screenshots — still outstanding

The Preview section is the one thing that can't be drafted or captured from a
browser. It needs the simulator or the watch.

Worth capturing at 466x466 for the fēnix 9 Pro, since the layout rewrite is the
headline change and the current previews are from the old fixed 260px layout:

1. Full view of a tempe slot showing current, min, max and the battery icon
2. The glance view
3. A slot using the internal sensor, showing `--` for min/max, so the caveat in
   the description has a picture to go with it

Note the simulator starts widget apps in glance mode — press Enter/Start to get
to the full view before capturing.

---

## 6. One thing from the reviews

Graham Heyes, 24 Dec 2025, 5 stars:

> "Excellent app, especially the offset! Is there a way to hide Tempe1? I only
> need 1 as well as the internal watch temperature."

That is exactly issue #2 — the `Number of Tempe` setting is already in the
settings menu but nothing reads it. A paying-attention user asked for the
feature that is half-built. Worth doing before or soon after this release, and
worth replying to.

For reference, TempX shipped the same thing in its 0.14: "ability to select
'none' for a tempe".

---

## Before submitting

- [ ] Run `tools/build-matrix.sh` and upload `export/TempeWidget.iq`
- [ ] Check the new launcher icon renders correctly on a real device or the
      simulator -- the per-size icons in `resources-icon*/` have never been
      seen on a watch
- [ ] Confirm the version field, description and What's New above
- [ ] Capture and replace the screenshots
- [ ] Remember the listing has 1K+ downloads and a 4.4 rating — this reaches
      real users
