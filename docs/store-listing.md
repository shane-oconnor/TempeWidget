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
  being fixed to one size. This should fix the widget on screens that are not
  260x260 - the Forerunner 965 and Instinct 2S in particular, where the old
  layout was drawn at the wrong size
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

## 7. Draft replies

Short, no promises beyond what is shipping.

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

## Before submitting

Done:

- [x] Merge PRs #12–#16. Everything is v1.0.0; there is no 1.0.1
- [x] Rebuild `export/TempeWidget.iq` from merged master with
      `tools/build-matrix.sh`. Built 2026-09-20 from `1be825f`: 56 products
      pass at type-check levels 1 and 2, level 1 with zero warnings, store
      export 100 of 100 devices, no skips. `tools/validate.py` reports 0
      errors and 0 warnings. The `.iq` is the artifact to upload — it is
      gitignored, so it exists only on the build machine and must be rebuilt
      if anything changes

Still to do, in the order that makes sense:

- [ ] **Look at the glance view once.** Its geometry was verified numerically
      on fēnix 9 Pro 51mm (359x130) and fēnix 6 (176x93) at slot counts 1, 2
      and 3, but nobody has seen it render. It is the view most changed in
      this release and the one users meet first. The simulator starts widget
      apps in glance mode, so it is the first thing on screen
- [ ] **Check the launcher icon on a device or the simulator.** The per-size
      renders in `resources-icon*/` have never been seen on a watch, and
      `resources-icon70` — the one venu2 needs — is newer than all the others
- [x] **Decided: keep all 56 products.** Confirmed 2026-09-20. The fēnix 8
      and 9 families, fr970 and venu2 stay in the uploaded `.iq` even though
      none has run on real hardware. A further 40 devices are candidates for
      a later release — see issue #20, which carries the build evidence
- [ ] Confirm the version field, description and What's New above
- [ ] Capture and replace the screenshots. The glance shot doubles as the
      check above, so take it first
- [ ] Upload the `.iq` and submit
- [ ] Reply to the reviewers once it is live (section 7). Three of them
      reported the `Number of Tempe` bug that 1.0.0 fixes, and two of those
      have been waiting since 2023
- [ ] Remember the listing has 1K+ downloads and a 4.4 rating — this reaches
      real users
