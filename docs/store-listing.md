# Connect IQ Store listing — draft copy

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

**Undecided, and it needs deciding before submitting.** The tagged v1.0.0 has
since been followed by four PRs (#12–#15) that add user-visible behaviour —
`Number of Tempe` actually working, settings applying without a relaunch, the
glance showing every slot, stale readings fading. Either:

```
1.0.0 Added fēnix 9 Pro
```

if those are folded in before anything is submitted — nothing has gone to the
Store yet, so 1.0.0 can still absorb them; or

```
1.0.1 Added fēnix 9 Pro
```

if v1.0.0 is treated as already spent. The What's New entry in section 3 is
written to cover the whole set either way; only the number changes.

---

## 2. Description (full replacement)

```
This widget allows you to quickly display the current temperature, plus the
24hr min and max, from up to three sources at the same time - Garmin tempe
sensors, your watch's built in temperature sensor, or a tempe paired over
Bluetooth. Swipe up and down to move between them, or use the glance view to
see them side by side without opening the widget.

Each slot is configured separately, with its own name, ID and calibration
offset.

Number of Tempe - choose 1, 2 or 3. Slots beyond the number you pick are
hidden, skipped when paging, and no longer searched for, so if you only want
one tempe and your watch's internal sensor you are not left swiping past an
empty third screen.

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

White Background - switches the display to dark text on a white background,
including the glance view.

Settings take effect straight away. Changing a name, offset, ID or the number
of slots applies while the widget is open, without closing and reopening it.

A reading that is more than halfway to its timeout is drawn dimmed, so you can
tell at a glance that a sensor has gone quiet before the value disappears
altogether.

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
- **Corrects a claim that was not true when it was drafted.** The old text
  here said the glance view showed "all three together". It did not — the
  glance was pinned to slot 0 and showed that one slot's current, min and max
  (issue #4). PR #13 made it actually show one column per configured slot, so
  the claim is now accurate. Worth knowing that it was aspirational, in case a
  similar line gets written again.
- Documents **Number of Tempe**, which was in the settings menu from the start
  but was read by nothing until PR #12 (issue #2).
- Documents that settings now apply live, and that stale readings dim.

---

## 3. What's New

This field holds the whole changelog, so the new entry goes on top and the rest
stays as it is.

```
1.0.0 Added fēnix 9 Pro, and the fēnix 8 and 9 families

- The "Number of Tempe" setting now works. It has been in the settings menu
  for years but nothing read it, so all three slots were always active. Pick
  1, 2 or 3 and the rest are hidden and no longer searched for
- Settings now apply while the widget is open. Changing a name, offset, ID or
  the number of slots no longer needs the widget closed and reopened
- The glance view now shows every slot you have configured, each with its own
  name. It previously only ever showed the first one, whatever you had set up
- The glance view now scales to the watch screen and follows the White
  Background setting, instead of being fixed to one size and always dark
- A reading more than halfway to its timeout is now drawn dimmed, so a sensor
  that has gone quiet is visible before the value disappears
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
- Debug logging no longer runs with Debug Mode switched off
- Cached readings are written to storage only when they change, rather than
  fifteen times every five seconds
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

So this is **not** copy to update. Uploading the new `.iq` adds the rows by
itself. Nothing to do by hand.

The product count has moved since this was first drafted: **56**, not 43. The
manifest picked up the fēnix 8 and fēnix 9 families, plus fr970 and venu2, as
their device definitions were installed locally. The store export now reports
100 of 100 devices built. That is a much wider device claim than 0.68 made, and
none of the new ones have been tested on hardware — worth a moment's thought
before submitting, since every one of them becomes a row on the listing.

---

## 5. Screenshots — still outstanding

The Preview section is the one thing that can't be drafted or captured from a
browser. It needs the simulator or the watch.

Worth capturing at 466x466 for the fēnix 9 Pro, since the layout rewrite is the
headline change and the current previews are from the old fixed 260px layout:

1. Full view of a tempe slot showing current, min, max and the battery icon
2. The glance view — now the more interesting shot, since it shows all three
   slots side by side rather than one
3. A slot using the internal sensor, showing `--` for min/max, so the caveat in
   the description has a picture to go with it

Note the simulator starts widget apps in glance mode — press Enter/Start to get
to the full view before capturing.

**The glance layout has never actually been looked at.** Its geometry was
verified numerically on fēnix 9 Pro 51mm and fēnix 6 at each slot count, but no
one has seen it render. Capturing screenshot 2 doubles as that check, so do it
before anything else here.

---

## 6. One thing from the reviews

Graham Heyes, 24 Dec 2025, 5 stars:

> "Excellent app, especially the offset! Is there a way to hide Tempe1? I only
> need 1 as well as the internal watch temperature."

That was exactly issue #2 — the `Number of Tempe` setting was already in the
settings menu but nothing read it.

**It is now built** (PR #12). Setting it to 1 leaves him a single tempe, and
pointing a second slot at -1 gives him the internal watch sensor alongside it,
which is precisely what he asked for. Worth replying to him when this goes
live; a 5-star reviewer who asks for a specific feature and then sees it ship
is worth the two minutes.

For reference, TempX shipped the same thing in its 0.14: "ability to select
'none' for a tempe".

---

## Before submitting

- [ ] Merge PRs #12–#15 and decide the version number (section 1)
- [ ] Run `tools/build-matrix.sh` from the merged master and upload the
      rebuilt `export/TempeWidget.iq` — the current one predates all four PRs
- [ ] Look at the glance view once. It has been measured, never seen
- [ ] Check the new launcher icon renders correctly on a real device or the
      simulator -- the per-size icons in `resources-icon*/` have never been
      seen on a watch, and `resources-icon70` is newer still
- [ ] Decide whether to keep all 56 products or trim the untested ones
      (section 4)
- [ ] Confirm the version field, description and What's New above
- [ ] Capture and replace the screenshots
- [ ] Remember the listing has 1K+ downloads and a 4.4 rating — this reaches
      real users
