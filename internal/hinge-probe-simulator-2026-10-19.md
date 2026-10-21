# Milestone 1 — iPhone Duo simulator hinge experiment

**Simulator measurements only · 19 October 2026**

## Verdict

Executed the native UI experiment, not a game loop. The probe received real
hinge callbacks through presets and Option-drags, measured a **0°–180° observed
range**, and retained its run ID, counters, and markers across outer/inner
display changes. Still partial and closed poses produced **zero additional
callbacks** during two explicitly bracketed holds.

**Do not interpret this as an all-green result or hardware validation.**

- **Point-click expectation failed:** three Option-clicks changed the Device Hub
  slider thumb but did not change the device pose or deliver a callback. Releasing
  Option also did not apply those clicked values. A subsequent preset worked.
- **Opening-drag anomaly:** status briefly became `partiallyOpen` at 34.671646°,
  reverted to `closed` at 34.996639°, stayed `closed` through 141.595322°, then
  returned to `partiallyOpen` at 157.712219°. The device surface was black during
  part of that drag, including the held midpoint screenshot. Callback logging
  continued. The run does not establish whether this was a Device Hub display
  handoff issue, runtime status policy, or another platform/probe interaction.
- Therefore **stable status thresholds and reliable point-click input remain
  unestablished**. Keep status separate from angle; do not tune gameplay from
  these simulator observations.

The Milestone 1 measurement report and raw evidence exist. No implementation
changes, core logic, scoring, calibration, or full game loop were added by this
test run.

## Environment and provenance

| Item | Verified value |
| --- | --- |
| Host | macOS 26.6.2, build 25G83 |
| Xcode | 27.1, build **27A9275** |
| Developer directory | `/Applications/Xcode-27.1.app/Contents/Developer` |
| Runtime | **iOS 27.1, build 24A94425**, arm64 |
| Runtime identifier | `com.apple.CoreSimulator.SimRuntime.iOS-27-1` |
| Device | **iPhone Duo**, type `com.apple.CoreSimulator.SimDeviceType.iPhone-Duo` |
| Device UDID | `04B8D6BA-28A9-4042-9F52-98105FBA14E5` |
| Simulator model identifier | `iPhone19,4` (provenance only, not used for layout) |
| UI client | Device Hub 27.1, bundle version 255.6.8.1 |
| App | `dev.ybae00.DuoProbe` |
| Sources | `DuoProbe/DuoProbe/{DuoProbeApp,ContentView,ProbeModel}.swift` |
| Built app used | `/Users/devin/.devin-files/duo-derived-data/Build/Products/Debug-iphonesimulator/DuoProbe.app` |
| Run ID | **`AD8F78E4-85CD-4A25-A696-907332790C78`** |
| Run start event | Unix `1792447938.093265`, 2026-10-19 **22:12:18.093265 UTC** |
| Last captured callback | #393, elapsed `569.2030915`, Unix `1792448507.297642` |

Xcode/runtime/device were checked before the experiment. The matching runtime
was installed for this run; existing 26.5 and 27.0 runtimes were retained.
The already-built app installed and launched without additional signing.
Build, lint, and shell unit tests were deliberately not rerun.

## Method

One annotated Device Hub screen recording covers the real app:

1. Add state marker 1. Exercise Closed, Partially Open, and Open presets.
2. Choose Opening, return to Closed, hold Option, and drag the actual under-bezel
   hinge slider toward Open in small, slow pointer movements. Capture a held
   midpoint, then continue and release.
3. Choose Closing and repeat in reverse, again capturing while mouse-down.
4. Choose Point clicks and click roughly quarter, three-quarter, and midpoint
   slider locations while holding Option. Observe each response; release Option.
5. Use Partially Open to establish a real partial pose. Choose Still; place
   markers 2 and 3 around an untouched timed hold.
6. Choose Closed hold, use Closed, and place markers 4 and 5 around another
   untouched timed hold. Reopen and inspect run ID and markers.

No angles were injected into the app or simulator through a data/API command.
Option key events and pointer gestures operated Device Hub's real UI. JSONL
was copied unchanged from the simulator app's Documents directory.

Only `kind == "hinge"` counts as a callback. Marker, phase, and lifecycle events
are snapshots, **not sensor updates**. `elapsed` is monotonic uptime since model
creation; `unixTime` is wall-clock time. UI values round to three decimals;
raw JSONL preserves the received floating-point values.

### Phase and marker timeline

All times below are elapsed seconds in the run above; raw records also contain
wall-clock timestamps.

| Event | Elapsed | Callback count | Pose snapshot |
| --- | ---: | ---: | --- |
| Marker 1, Presets | 140.668330208 | 1 | closed, 0° |
| Opening selected | 223.858138458 | 37 | fullyOpen, 180° |
| Preparatory Closed preset finishes | 233.940285375 | 52 | closed, 0° |
| Opening drag first callback | 262.783564500 | 53 | closed, 5° |
| Opening drag finishes | 287.205829542 | 167 | fullyOpen, 180° |
| Closing selected | 311.656392042 | 167 | fullyOpen, 180° |
| Closing drag first callback | 327.343653375 | 168 | partiallyOpen, 174.865128° |
| Closing drag finishes | 347.627340292 | 336 | closed, 0° |
| Point clicks selected | 376.858982792 | 336 | closed, 0° |
| Next preset first callback, after failed point clicks | 436.263258917 | 337 | closed, 5° |
| Partially Open preset finishes | 437.906578250 | 361 | partiallyOpen, 127.777779° |
| Still selected | 457.156535875 | 361 | partiallyOpen, 127.777779° |
| Marker 2, still hold start | 463.137617583 | 361 | partiallyOpen, 127.777779° |
| Marker 3, still hold end | 485.468617917 | 361 | partiallyOpen, 127.777779° |
| Closed hold selected | 507.356022625 | 361 | partiallyOpen, 127.777779° |
| Closed preset finishes | 520.473785500 | 375 | closed, 0° |
| Marker 4, closed hold start | 530.027599292 | 375 | closed, 0° |
| Marker 5, closed hold end | 552.773812417 | 375 | closed, 0° |
| Reopening finishes | 569.203091500 | 393 | fullyOpen, 180° |

Phase labels persist until changed. In particular, the Opening phase includes
the preparatory **closing** preset (#38–52), Point clicks includes the later
Partially Open preset (#337–361), and Closed hold includes reopening
(#376–393). Those callbacks must not be misattributed to the clicks or holds.

## Range, presets, and callbacks

| Measurement | Actual observation |
| --- | --- |
| Lowest callback angle | **0°** |
| Highest callback angle | **180°** |
| Closed preset endpoint | **0°, `closed`** |
| Partially Open preset endpoint | **127.77777862548827°, `partiallyOpen`** |
| Open preset endpoint | **180°, `fullyOpen`** |
| Total real callbacks | **393**, numbered consecutively 1–393 |
| Nil callbacks | **0** |
| Status callback totals | closed 122; partiallyOpen 268; fullyOpen 3 |
| Initial callback | #1 at elapsed 0.593490792: 0°, closed |
| Initial callback interpretation | Observed once in this run; not a guaranteed delivery contract |

These are observations of this runtime/device configuration, not a published
range, precision guarantee, or hardware measurement. Fractional values and
duplicate-angle callbacks both occurred; neither proves physical sensor resolution.

## Status transitions: sampled brackets, not thresholds

Each row contains the **last old-status callback → first new-status callback**.
Angles are rounded to six decimals and elapsed times to six decimals here.
Direction comes from the actual gesture/preset, not from deriving pose from angle.

| Operation | Last old callback: # · elapsed · angle · status | First new callback: # · elapsed · angle · status |
| --- | --- | --- |
| Preset opening toward partial | #3 · 153.860132 · 14.680717° · closed | #4 · 153.913782 · 35.782295° · partiallyOpen |
| Preset opening to Open | #36 · 165.633308 · 173.832642° · partiallyOpen | #37 · 165.830093 · 180° · fullyOpen |
| Preparatory closing preset | #37 · 165.830093 · 180° · fullyOpen | #38 · 232.794184 · 172.685638° · partiallyOpen |
| Preparatory closing preset | #41 · 232.979174 · 98.600075° · partiallyOpen | #42 · 233.014151 · 79.238358° · closed |
| **Opening drag** | #65 · 264.345946 · 17.966101° · closed | #66 · 264.579321 · 34.671646° · partiallyOpen |
| **Opening drag: unexpected reversal** | #66 · 264.579321 · 34.671646° · partiallyOpen | #67 · 265.329893 · 34.996639° · closed |
| **Opening drag: closed over large angle span** | #141 · 284.729031 · 141.595322° · closed | #142 · 284.933850 · 157.712219° · partiallyOpen |
| **Opening drag** | #166 · 287.117955 · 174.526215° · partiallyOpen | #167 · 287.205830 · 180° · fullyOpen |
| **Closing drag** | #167 · 287.205830 · 180° · fullyOpen | #168 · 327.343653 · 174.865128° · partiallyOpen |
| **Closing drag** | #329 · 346.995679 · 13.787528° · partiallyOpen | #330 · 347.030966 · 11.913653° · closed |
| Partial preset after point clicks | #338 · 436.279467 · 12.367605° · closed | #339 · 436.363217 · 32.745239° · partiallyOpen |
| Closed preset before hold | #366 · 519.512138 · 75.801018° · partiallyOpen | #367 · 519.547493 · 59.163849° · closed |
| Reopening after hold | #377 · 568.080206 · 14.833305° · closed | #378 · 568.163136 · 42.908218° · partiallyOpen |
| Reopening after hold | #392 · 568.979320 · 173.603455° · partiallyOpen | #393 · 569.203092 · 180° · fullyOpen |

The old callback in the open-to-partial rows may precede a long idle period.
It is still the last actual old-status sample, not a measurement of the
unobserved exact crossing. Preset transitions differ markedly from slow-drag
transitions. This single pass cannot establish hysteresis or stable boundaries.

## Callback timing while dragging and still

For a window with N callbacks, mean interval rate below is
`(N - 1) / (last elapsed - first elapsed)`. It is **not** a promised sensor rate.
All callbacks in each stated window count, including repeated angles.

| Gesture window | Callbacks | Observed span | Interval min / median / max | Mean interval rate |
| --- | ---: | ---: | --- | ---: |
| Opening drag #53–167 | 115 | 24.422265042 s | 0.014318 / 0.046194 / 10.989556 s | 4.667872 Hz |
| Closing drag #168–336 | 169 | 20.283686917 s | 0.011342 / 0.035647 / 5.930935 s | 8.282518 Hz |
| Opening initial moving burst #53–63 | 11 | 0.495476750 s | 0.014318 / 0.033592 / 0.116502 s | 20.182582 Hz |
| Opening final moving burst #157–167 | 11 | 0.544656458 s | 0.034471 / 0.036832 / 0.113138 s | 18.360197 Hz |
| Closing initial moving burst #168–177 | 10 | 0.519499875 s | 0.016661 / 0.033359 / 0.217245 s | 17.324355 Hz |

Opening had 76 distinct reported angles; closing had 119. The pointer was moved
in slow increments, with deliberate mouse-down pauses for screenshots.
**The 10.990 s and 5.931 s maximum gaps include those intentional pauses**;
do not describe them as continuous-motion callback stalls. Active burst windows
are examples with distinct successive angles, not a claim about every angle.

| Untouched hold | Explicit marker bounds | Duration | Real hinge callbacks within bounds |
| --- | --- | ---: | ---: |
| Partial, 127.77777862548827° | markers 2 → 3, elapsed 463.137617583 → 485.468617917 | **22.331000333 s** | **0**; count stays 361 |
| Closed, 0° | markers 4 → 5, elapsed 530.027599292 → 552.773812417 | **22.746213125 s** | **0**; count stays 375 |

### Are closed readings real, or just a retained value?

**Real closed-status callbacks arrived.** For example, the closed-preset
sequence had callback #367 at 59.16384887695313° with `closed`, #374 at
6.291470527648927° with `closed`, and #375 at **0° with `closed`**.
The latter is a `hinge` event at elapsed 520.4737855, not a marker snapshot.
The closing drag independently reached #336 at 0°, closed.

**No periodic callbacks arrived during the untouched closed hold.**
Markers 4 and 5 retained the previous callback value; those two 0° snapshots
must not be called new closed readings. The latest timestamp/interval also
remained stale on screen while still, as expected for this diagnostic probe.

## Display changes and state

- The UI visibly changed from the compact outer-display form while closed to
  the wider inner-display form when opened/partial, and back during folding.
- Run ID stayed `AD8F78E4-85CD-4A25-A696-907332790C78`.
- Marker 1 survived presets and both drags. Markers 2–5 incremented normally,
  and marker **5** remained after reopening. Callback count reached **393**
  without resetting. One run/file contains the entire sequence.
- Lifecycle evidence contains one `runStarted`, one `rootAppeared` at
  0.344419042 s, and one `scenePhase:active` at 0.570892917 s.
  **No `rootDisappeared` or additional root appearance was logged.**
  Thus state survival through the observed display/size changes is established;
  survival of an actual root/scene replacement was **not exercised/proven**.
- The plain diagnostic Form sometimes requires scrolling to see local log
  details, and the fold can pass through content. The opening black surface
  is a limitation in this run. No fold-safe, reserved-region, rotation, or
  Split View completion is claimed.

## Visual evidence

Full screenshots below show Device Hub and the genuine app, with no Apple
account page. The opening black surface and point-click mismatch are preserved,
not replaced with a mock or hidden.

| Closed hold endpoint — 0°, count 375, marker 5 | Partial hold endpoint — 127.778°, count 361, marker 3 |
| --- | --- |
| ![Closed hold endpoint](https://app.devin.ai/attachments/51fc4111-a81a-43af-abbc-06435521e090/ss_c53ba81a.png) | ![Partial hold endpoint](https://app.devin.ai/attachments/b43bce35-7379-4d39-a3b4-17ff5a51bad9/ss_6a4fb77c.png) |

| Opening midpoint — black surface while mouse held | Closing midpoint — visible 101.607° while mouse held |
| --- | --- |
| ![Opening drag black surface](https://app.devin.ai/attachments/7f50b444-6092-4a9b-aee2-70f772cbb65e/ss_72c7a636.png) | ![Closing drag intermediate state](https://app.devin.ai/attachments/f9a31a9c-e161-4884-b104-1ccbd207cecc/ss_782b2956.png) |

| 🔴 Before folds/holds — original run ID, marker 1 | 🟢 After reopening — identical run ID, marker 5 |
| --- | --- |
| ![Before state survival](https://app.devin.ai/attachments/b0bd2590-0b66-40e6-a729-42e30a52cd32/ss_c8aa7c31.png) | ![After state survival](https://app.devin.ai/attachments/2ed0f16f-e9f4-44c5-b2f4-bf7f638d8f1b/ss_13274ba2.png) |

| First point click — thumb left of midpoint, callback 336 | Second point click — thumb right of midpoint, still callback 336 |
| --- | --- |
| ![Point click left unchanged reading](https://app.devin.ai/attachments/00e1ecec-242a-4890-8aa7-8442c6972633/ss_a50d2197.png) | ![Point click right unchanged reading](https://app.devin.ai/attachments/87f13b06-f018-40a7-b939-a6c8b5491314/ss_5dbe5aca.png) |

## Raw artifacts and reproducibility

- Raw log, unchanged: [`hinge-probe-AD8F78E4-85CD-4A25-A696-907332790C78.jsonl`](hinge-probe-AD8F78E4-85CD-4A25-A696-907332790C78.jsonl),
  **406 records / 87,746 bytes**, including 393 `hinge` records.
  SHA-256 (matches the original app Documents file):
  `d07d2893e0b5a83e60cb22675a2e4c15d764939d4f55d20c605f57f9044a06ed`.
- Recording:
  `/Users/devin/screencasts/duo-milestone1/duo-milestone1-edited.mp4`.
- Test plan:
  `/Users/devin/.devin-files/duo-hinge-test-plan.md`.
- Original simulator log:
  `/Users/devin/Library/Developer/CoreSimulator/Devices/04B8D6BA-28A9-4042-9F52-98105FBA14E5/data/Containers/Data/Application/B3DA83B0-9877-4E50-8D62-A7731909D236/Documents/hinge-probe-AD8F78E4-85CD-4A25-A696-907332790C78.jsonl`.

Verified setup commands for a future macOS blueprint (no blueprint currently
exists). Use the explicit developer directory; do not change global xcode-select.

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer
xcodebuild -version
xcodebuild -downloadPlatform iOS -buildVersion 27.1 -architectureVariant arm64
xcrun simctl list runtimes
xcrun simctl list devices
xcrun simctl list devicetypes
# iPhone Duo was automatically created when runtime became available.
# Reuse its actual UDID; this run used:
xcrun simctl boot 04B8D6BA-28A9-4042-9F52-98105FBA14E5
xcrun simctl bootstatus 04B8D6BA-28A9-4042-9F52-98105FBA14E5 -b
open /Applications/Xcode-27.1.app/Contents/Applications/DeviceHub.app
xcrun simctl install 04B8D6BA-28A9-4042-9F52-98105FBA14E5 \
  /Users/devin/.devin-files/duo-derived-data/Build/Products/Debug-iphonesimulator/DuoProbe.app
xcrun simctl launch 04B8D6BA-28A9-4042-9F52-98105FBA14E5 dev.ybae00.DuoProbe
xcrun simctl get_app_container \
  04B8D6BA-28A9-4042-9F52-98105FBA14E5 dev.ybae00.DuoProbe data
```

The runtime download reported 7.85 GB for arm64. Device Hub is under
`Contents/Applications`, not the older `Contents/Developer/Applications`
Simulator path. Native automation required PID targeting in this session
(app-name lookup did not resolve it); PID 7824 was session-specific.

## Remaining coverage

- One simulator pass only; no hardware, physical detents, power/background
  behavior, relaunch persistence, no-hinge device, or nil-hinge scenario tested.
- No stable transition boundary, precision, or update-rate guarantee inferred.
- Point-click callback behavior and the opening status/black-surface anomaly
  need follow-up before treating Device Hub as a fully reliable input surface.
- No core game, calibration, haptic/audio, scoring, full fold-safe layout, or
  App Store claims. Hardware tuning remains a later milestone.
- Nothing further is needed from the user to read/reproduce this completed
  local measurement; physical-device validation still requires actual hardware.
