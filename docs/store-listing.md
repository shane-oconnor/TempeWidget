# Connect IQ Store listing — v1.1.1

**1.1.1 uploaded 2026-09-26 as `1.1.1 glance min/max`.** Shane ran 1.1.0 on
the watch with the internal sensor only, reported it good, and asked for the
glance's "--" min and max to show values for that sensor (PR #26). Uploaded
`export/TempeWidget.iq`, 3,433,013 bytes, sha256 `c4754fb5…`, from master
`dbf3a0d` (tag `v1.1.1`, .iq attached to the GitHub release): 96 products,
154 of 154. Panel: `Status: Verified / Signature: Verified`. The 1.1.1 entry
was prepended to the live What's New on the step 2 form (3762 chars). As with
1.1.0, the listing then showed "Version update pending" for Garmin's check of
up to two hours; 1.1.0 had cleared that check overnight. Details of the 1.1.0
upload follow.

## Release note: 1.1.0, uploaded 2026-09-25

**Uploaded 2026-09-25 as `1.1.0 auto Tempe`.** Shane asked for it to go to
production from a remote location, without a hardware test, and was told the
risk; the beta (below) went up first the same evening. Uploaded
`export/TempeWidget.iq`, 3,396,483 bytes, sha256 `7c22b905…`, built from
master `71204cd` (tag `v1.1.0`, the same file is attached to the GitHub
release): 96 products, store export 154 of 154. Edit Details went first:
new description, What's New prepended over a condensed 1.0.0 entry, four new
screen images and a new cover. The verification panel read `Status:
Verified / Signature: Verified`. Straight after submitting, the listing showed
**"Version update pending"** rather than the new version line, so Garmin now
holds a new version for a check before it goes live. Compatible Devices were
still the 1.0.0 set at that moment.

Sections 1–3 below are what was submitted. The notes on the 1.0.0 release
that follow are kept for the diff.

## Beta: `1.1.0 beta 1`, uploaded 2026-09-25 (remove once 1.1.0 is live and tested)

Shane was away from the watch, so the release candidate went up as a separate
**beta app** rather than a sideload:

- Listing: https://apps.garmin.com/apps/f598a2ac-0a77-4d9e-acfd-971e3d3a63c1
- Title `TempeWidget Beta`, version field `1.1.0 beta 1`, category Weather,
  ANT+ profile Environment, contact and source URL as the main listing.
- Built with `tools/build-beta.sh` from the `housekeeping` branch at `1f2e418`
  plus the script commit: manifest id `7c1d9a2e-5b64-4f0e-9d3a-2e8f6b1c4a57`,
  app name "TempeWidget Beta", 3,399,480 bytes, 154 of 154 devices.
- The portal's **Beta App** checkbox ("This app is for testing purposes only")
  makes it a Garmin beta: the page says *"Only you will be able to download and
  test the app"*, it is installed from the Connect IQ phone app on the same
  Garmin account, and it sits under "Beta Apps" on the developer dashboard.
  A beta id can never become a public app - the public release goes to the
  main listing under the real id, as planned.
- The verification panel said `Status: Verified` and `Signature check
  failed.`; the validate response had an empty `validationResult` with
  `signatureCheckSuccessFul: false`. For a brand-new app id there is no earlier
  key to match, and the form accepted it. The main listing's stored file
  reports `true` with the same key.

---

**Published 2026-09-20.** The live listing now reads `1.0.0 fēnix 8/9`,
replacing `0.68 Added EPIX`. Uploaded `export/TempeWidget.iq` at 2,417,396
bytes: 96 products, store export 154 of 154 devices, level 1 at zero warnings.
Description, What's New, all three screen images and the cover image went up
with it. Garmin regenerated Compatible Devices from the .iq, and Venu 3 now
appears on the listing, which confirms the new binary is the one live.

**Verified on hardware afterwards:** Shane ran it on his own fēnix 9 Pro 51mm
and reported it working. That closes the release's biggest open risk - until
then the only hardware check in the whole cycle was the earlier 466x466 layout
check, and everything since had been verified by simulator and by reading.

What is below is what was submitted, kept so the next release can diff against
it.

App: **Tempe Widget** by ShaneO
Listing: https://apps.garmin.com/apps/194a50be-400a-432a-9efa-402b4b7cae18
Was live before this release: version "0.68 Added EPIX", 3 June 2024.
4.4 from 19 reviews, 1K+ downloads.

Nothing below has been submitted. These are drafts for review.

Kept in the repo so the copy is versioned alongside the release it describes.
Update it when the listing changes, and note what actually went live.

---

## 1. Version field

The Store version field is free text. It currently reads `1.0.0 fēnix 8/9`
(live since 2026-09-20, when it replaced `0.68 Added EPIX`).

```
1.1.1 glance min/max
```

(1.1.0 went up as `1.1.0 auto Tempe`.)

**The field is capped at 20 characters.** That is not documented anywhere -
it is `maxlength=20` on the input, and it only appears during *Upload New
Version*, not on the Edit Details form. The drafted string was
`1.0.0 fēnix 8/9, Venu 3/4, Instinct 3 and more` at 46 characters and would
have been silently truncated. `tools/store-copy.py` now fails on anything
over 20, so this cannot repeat.

Fifteen characters buys a number and one headline, which is exactly the shape
of `0.68 Added EPIX`. The full device list and the fixes live in What's New,
which has 4000.

Everything in the repo is v1.0.0. Nothing has been uploaded to Connect IQ, so
the tag absorbs all of it — the device support, the fixes, and the four PRs
that followed (#12–#15). There is no 1.0.1.

---

## 2. Description (full replacement)

```
This widget allows you to quickly display the current temperature, plus the
24hr min and max, from up to three sources at the same time - Garmin tempe
sensors, your watch's built in temperature sensor, or a tempe paired over
Bluetooth. Swipe up and down to move between them, or use the glance view to
see the first sensor's temperature alongside its 24hr min and max without
opening the widget.

Your tempes are found automatically. Switch them on, open the widget, and each
one gets its own page - two tempes land on two pages without typing any ID
into the phone. A sensor that is switched off or out of range simply has no
page, so there is nothing to count or configure.

Each page shows the reading large, with the tempe's 24hr low and high beneath
it and a bar showing where the reading sits between them, how long ago the
reading arrived, the tempe's battery, and the sensor's ID so two tempes can be
told apart. The label takes a colour from the temperature, blue through red.
The page for your watch's own sensor draws the last six hours as a line.

Hold the UP button (or press the menu button) for a menu on the watch: a
list of which tempe each slot is using, "Forget Tempes" to start the search
over, and the battery and white background switches.

Each slot is configured separately in the Connect IQ app, with its own name,
ID and calibration offset.

Sensor ID - leave this at 0 and the widget fills it in with the first tempe it
finds that no other slot is using, so the name and offset stay with that
tempe from then on. Set it back to 0 to search again. You can also type a
tempe's ANT ID yourself. Use -1 for your watch's internal temperature sensor,
or -2 for a tempe paired over Bluetooth.

Please note the 24hr min and max are reported by the tempe sensor itself, so
they are only available on tempe slots. A slot using the watch's internal
sensor shows the watch's own six hour history and that window's low and high
instead; a tempe paired over Bluetooth shows the current temperature on its
own. Some watches don't give access to the internal sensor or to a paired
tempe at all; where the watch doesn't provide a reading you will see "--".
Sorry, I can't override this.

Name - the label shown above the reading, up to 12 characters. Handy if you have
one tempe outside and one in the shed.

Keep a reading for - how long the widget keeps a value when it isn't getting
updated. The reading dims at the halfway point; once the time passes it is
cleared and the page goes with it.

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

Settings take effect straight away. Changing a name, offset or ID applies
while the widget is open, without closing and reopening it.

Debug - if you set this to true, sensor and channel events are written to the
log.

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
- Adds the **min/max caveat**, which is the single most likely source of
  "it's broken" reviews. Corrected 2026-09-20 after photographing it: the
  earlier wording said the internal sensor "will show `--` for min and max",
  and it does not. The full view omits the Min and Max lines altogether for a
  slot that has no min/max - `docs/screenshots/3-internal.png` shows exactly
  that, just a label and one reading. `--` is what the *glance* shows. Worth
  remembering that reading the code said "null", and null renders two
  different ways in the two views.
- Fixes **"emitter" to "ekutter"**, which is the actual developer name on the
  TempX listing. Check you're happy with this — it's your credit line.
- Adds the GitHub link in the body. The listing already has a Source Code link
  pointing there, but it's easy to miss.
- **Corrects a claim that was not true when it was drafted.** The old text
  here said the glance view showed "all three together". It never has. The
  glance shows the first sensor's current reading with its 24hr min and max,
  which on a strip only tall enough for one row of numbers says more than three
  current readings would - a temperature on its own tells you much less than a
  temperature next to where it has been. The line now describes that. Worth
  knowing the original was aspirational, in case a similar one gets written.
- Documents **Number of Tempe**, which was in the settings menu from the start
  but was read by nothing until PR #12 (issue #2).
- Documents that settings now apply live, and that stale readings dim.

---

## 3. What's New

This field holds the whole changelog, so the new entry goes on top and the rest
stays as it is.

```
1.1.1 glance min/max

- The glance now shows the watch sensor's six hour low and high when no
  tempe is present, instead of "--" in the Min and Max columns. The full view
  already showed them

1.1.0 auto Tempe

- Tempes are found automatically. One scanning channel hears every tempe in
  range and gives each its own page, so two tempes no longer race for the same
  slot. The ID a slot settles on is written into its setting so the name and
  offset stay with that tempe
- The "Number of Tempe" setting is gone. A sensor has a page while it has a
  reading; one that is off or out of range has none
- The full view is redrawn: the reading is large, in a vector font on watches
  that have one, with the 24hr low and high beneath it and a bar showing where
  the reading sits between them. The label is coloured by temperature
- Shows how long ago each reading arrived, as asked for in the reviews
- Shows the sensor's ID under its label, so two tempes can be told apart
- The watch's own sensor page draws the last six hours as a line, with that
  window's low and high
- A menu on the watch (hold UP or press the menu button): which tempe each
  slot is using, Forget Tempes to search again, and the battery and white
  background switches
- The Connect IQ settings are grouped, the timeout is a list of minutes, and
  the ID codes are explained under the setting instead of in its title

1.0.0 fēnix 8/9, Venu 3/4, Instinct 3 and more

- The "Number of Tempe" setting now works. It has been in the settings menu
  for years but nothing read it, so all three slots were always active. Pick
  1, 2 or 3 and the rest are hidden and no longer searched for
- Settings now apply while the widget is open. Changing a name, offset, ID or
  the number of slots no longer needs the widget closed and reopened
- The glance view now labels what it is showing - the first sensor's
  temperature with its 24hr min and max beside it - instead of an unlabelled
  row of figures
- The glance view now scales to the watch screen and follows the White
  Background setting, instead of being fixed to one size and always dark
- A reading more than halfway to its timeout is now drawn dimmed, so a sensor
  that has gone quiet is visible before the value disappears
- Fixed sub-zero temperatures reading slightly too warm. Below freezing the
  current reading was out by 0.01 C and the 24hr min and max by 0.1 C
- Fixed a crash every few seconds on watches with no stored temperature
  history, cached readings timed against a clock that resets on restart, the
  offset showing "--", and the battery icon ignoring White Background
- A critical tempe battery level is now flagged, not just a low one
- Rebuilt the full screen layout so it scales to the watch screen instead of
  being fixed to 260x260, which should fix the Forerunner 965 and Instinct 2S
- Sharper launcher icons, debug logging only in Debug Mode, and far fewer
  storage writes
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

The product count has moved a long way since this was first drafted: **96**,
not 43, and the store export reports **154 of 154 devices built** against the
60 rows the live 0.68 listing shows.

It grew in two steps. The fēnix 8 and 9 families, fr970 and venu2 arrived on
their own as their device definitions were installed locally. Then 40 more were
added deliberately — every installed device definition was probe-built to find
which ones actually work, and these are the ones that build cleanly and keep
the glance view. Issue #20 records the evidence, including the 25 that were
rejected because their app type has no glance and the 11 Edge and Approach
devices held back as a different product category.

**None of the new devices has been tested on hardware.** That is a much wider
claim than 0.68 made, on a listing with 1K+ downloads and a 4.4 rating. What
is verified: all 96 build at both type-check levels with level 1 at zero
warnings, all expose Toybox.Ant, AntPlus and SensorHistory, memory use is
about 15% of the tightest limit, and the glance layout was traced on the four
screen extremes — Venu X1 at 448x486, Instinct E 40mm at 166x166, fēnix 9 Pro
51mm and fēnix 6 — with no column overflowing at any slot count.

---

## 5. Screenshots — still outstanding

The Preview section is the one thing that can't be drafted or captured from a
browser. It needs the simulator or the watch.

Worth capturing at 466x466 for the fēnix 9 Pro, since the layout rewrite is the
headline change and the current previews are from the old fixed 260px layout:

1. Full view of a tempe slot showing current, min, max and the battery icon
2. The glance view — the first sensor's reading with its min and max
3. A slot using the internal sensor, showing `--` for min/max, so the caveat in
   the description has a picture to go with it

Note the simulator starts widget apps in glance mode — press Enter/Start to get
to the full view before capturing.

**The glance layout has never actually been looked at.** Its geometry was
verified numerically on fēnix 9 Pro 51mm and fēnix 6 at each slot count, but no
one has seen it render. Capturing screenshot 2 doubles as that check, so do it
before anything else here.

---

## 6. What the reviews are telling us

19 reviews, 4.4 average. Read in full, they say three useful things.

### a. "Number of Tempe" is the most-reported bug in the listing

Three separate people, across two years, reported the same thing:

> **Jacek Betler**, 27 Nov 2023, 0.66 — "The option Numbers of Tempe dasn't
> work on Fenix 7."

> **Liryc**, 26 Jan 2024, 0.67 — "I set the Tempe number to 1, but still get 3
> displays (with Tempe2 still displayed). Is that a bug ?"

> **Graham Heyes**, 24 Dec 2025, 0.68, 5 stars — "Excellent app, especially the
> offset! Is there a way to hide Tempe1? I only need 1 as well as the internal
> watch temperature."

It was a bug, it was not device-specific, and Liryc was right to ask. The
setting had been in the menu since 0.6 and no source file ever read it
(issue #2). **Fixed in 1.0.0.** This is the single strongest thing in the
What's New entry and is why it leads.

All three are worth replying to. Liryc and Jacek waited two years for an
answer; Graham is a 5-star reviewer who asked for something that now exists.

### b. Two "doesn't work" reports are both the old fixed layout

> **Роман Левенко**, 23 Jul 2023, 0.65 — "Doesn't work with FR 965"

> **Kaloyan Palatov**, 24 May 2025, 0.68 — "Doesn't really work/buggy on Garmin
> instinct 2S Solar"

Neither is a missing device. `fr965` has been in the manifest since the initial
commit, and `instinct2s` is the product id Garmin uses for "Instinct® 2S /
Solar / Dual Power", so both watches were nominally supported when those
reviews were written.

What they have in common is screen size. The layout before 1.0.0 was hardcoded
to 260x260:

| Device | Resolution | Against a 260x260 layout |
|---|---|---|
| Forerunner 965 | 454x454 | drawn at about half size, off centre |
| Instinct 2S / Solar | 163x156 | overflows the screen, and is not square |
| fēnix 7 / 7 Pro | 260x260 | correct — the size it was built for |

That is a good explanation for "doesn't work" on exactly those two watches and
not on the fēnix line, and 1.0.0 derives every dimension from `dc` instead.
**Not proven** — neither watch is here to test on — but it is the most likely
cause, and the What's New entry now names both devices so those reviewers see
it.

### c. One report that is probably not a bug

> **Japigia**, 6 Jun 2024, 0.68 — "The Only bug is that Min and max Is not
> showing at all on fenix 7 pro."

fēnix 7 Pro is 260x260, the native size for the old layout, so this is not the
layout problem above. The page 1 parsing is not it either: it was checked field
for field against openant's Environment profile against a real tempe while
fixing issue #11.

The likely causes, in order:

1. The slot is on the internal sensor (ID `-1`), which has no 24 hour min or
   max at all and correctly shows `--`. The description never said so before;
   section 2 now does, and this is the single most likely source of
   "it's broken" reviews.
2. A tempe that has not yet accumulated 24 hours of history broadcasts the
   invalid sentinel, which also shows `--`.

Tracked as an issue rather than guessed at. If it turns up again after 1.0.0
ships with the clearer description, it is worth asking which ID the slot is on.

### d. Feature requests, not defects

> **Niki**, 1 Aug 2023, 0.65 — "Please add time and date of last Tempe update
> and vibration when new data is received."

The first half is nearly free: `TempItem.tmLast` already holds the timestamp
and `durStr()` already formats an age — nothing displays it. The second half is
a bigger question, since a widget vibrating on every sensor broadcast would be
intrusive and costs battery. Both filed, neither in 1.0.0.

### e. What people like, worth protecting

The offset is the most praised feature — Emerson twice, and Graham led with it.
Three reviewers value multiple tempes at once (Snowcat runs three). Two German
reviewers single out how simple it is to configure. None of that should get
harder in the name of new features.

---

## 7. Replies to reviewers — NOT POSSIBLE

**The Connect IQ Store has no reply-to-review feature.** Checked on 2026-09-20
while logged in as the developer: there is no reply or respond control on the
app page, the developer dashboard has only Uploaded Apps / Settings / Merchant
Account, and the unlabelled menus beside the reviews are the site's own
navigation. "Contact Developer" is inbound only - it lets a user email you and
gives you no way to reach them. Garmin does not expose reviewer contact
details.

This was an error in the earlier draft of this file, which listed "reply to the
reviewers" as a task without anyone checking the portal supported it.

**The What's New entry is the reply**, and was written to carry that load: it
answers the `Number of Tempe` reports directly and names the Forerunner 965 and
Instinct 2S in the layout line, so the five reviewers concerned will see their
complaint addressed when they next look at the app.

The drafts below are kept for use if anyone makes contact through GitHub or the
Contact Developer link.

**Graham Heyes** (and the same answer suits Liryc and Jacek Betler):

```
Thanks Graham, and sorry for the slow reply. You were right - "Number of
Tempe" was in the settings but the widget never actually read it, so it
always showed three. That is fixed in 1.0.0. Set Number of Tempe to 2, leave
the first slot on ID 0 for your tempe, and set the second slot's ID to -1 for
the watch's internal sensor. You will get exactly the two screens you wanted.
```

**Kaloyan Palatov:**

```
Thanks for flagging it. The layout was fixed to one screen size, which did not
suit the Instinct 2S at all. 1.0.0 rebuilds it to fit whatever screen it is
on - worth another try, and do let me know if anything still looks wrong.
```

**Роман Левенко:**

```
The layout was hardcoded for a 260x260 screen, which would have looked wrong
on the 965's larger display. 1.0.0 scales to the screen properly. Worth
another try.
```

**Japigia:**

```
Thanks. Worth checking which ID that slot is set to - the 24hr min and max
come from the tempe itself, so a slot on the internal sensor (-1) only ever
shows the current temperature and "--" for min and max. A tempe also needs 24
hours before it reports them. If it is a tempe that has been running longer
than that, let me know and I will dig further.
```

**Niki:**

```
Thanks - the time since the last update is a good idea and I have it on the
list. Vibration on every update I am more cautious about, as a tempe
broadcasts often and it would be both distracting and hard on the battery.
```

## Before submitting — all done 2026-09-20

- [x] Merge PRs #12–#16. Everything is v1.0.0; there is no 1.0.1
- [x] Rebuild `export/TempeWidget.iq` from merged master. 96 products, both
      type-check levels, level 1 at zero warnings, 154 of 154 devices
- [x] Look at the glance view. Done, and it found a real defect: captions were
      clipping to `Tempe` / `Tempe` / `Interna`, two columns labelled the same
- [x] Check the launcher icons. Covered by the hardware run
- [x] Decide the device list — 96 products, all kept
- [x] Confirm the version field, description and What's New
- [x] Capture and replace the screenshots — three, with the watch frame and
      band, plus a new 500x500 cover
- [x] Upload the `.iq` and submit
- [x] **Verified on a real fēnix 9 Pro 51mm afterwards and working**

Not possible, and struck from this list: replying to the reviewers. See
section 7 — the Store has no such feature.

## For the next release

- `tools/release-preflight.sh` first; it refuses a stale `.iq`
- `tools/sim-shots.py` for the screenshots, from a venv with
  `pyobjc-framework-Quartz` and `pillow`
- `tools/store-copy.py` for the three text fields, and it now enforces the
  **20 character** limit on the version string
- Watch the reviews from Forerunner 965 and Instinct 2S owners. Those two
  complaints were diagnosed as the old fixed 260x260 layout and should stop;
  that theory has never been tested on either device
