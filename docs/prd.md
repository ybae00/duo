# Duo — Product Requirements

Status: draft, 19 October 2026. iPhone Duo goes on sale 23 October 2026. Nothing in this document has been run on hardware.

Build instructions for agents: [agent.md](agent.md). The platform research notes are kept outside this repository.

## 1. Summary

Duo is a native iPhone game for iPhone Duo, Apple’s foldable iPhone. The game shows a target angle. The player folds the phone until its hinge matches that angle. The closer and faster the match, the higher the score.

The only input is the physical hinge. The game reads it through Apple’s hinge API in iOS 27.1. It is not playable on an iPhone without a hinge, and it cannot be a web app, because Safari exposes no hinge angle.

## 2. Goals and non-goals

### Goals

- A player can open the app on iPhone Duo, see a target angle, fold to it, and get a result, with no setup beyond a one-time calibration.
- Matching feels fair: a match is judged against a tolerance, not an exact degree, and the target is always physically reachable on that phone.
- The game keeps working while the phone moves between the outer and inner displays during a fold.
- It ships on the App Store as a normal iPhone app built with Xcode 27.1 and the iOS 27.1 SDK.

### Non-goals for version 1

- A web, PWA, or wrapped web view version.
- Android or other foldables.
- Accounts, a backend, multiplayer, Game Center, ads, or in-app purchases.
- A playable mode on iPhones without a hinge.
- Using the accelerometer or gyro to estimate the fold. The hinge reading is the only source.

## 3. Platform facts the product depends on

Verified in Apple’s documentation as of 19 October 2026:

- SwiftUI `View.onHingeChange(isEnabled:_:)` calls back with the previous and current `DeviceHingeContext`. `context.hinge` is an optional `DeviceHinge`.
- `DeviceHinge.angle` is a SwiftUI `Angle`. Its `.degrees` gives degrees. UIKit’s `UIHinge.angle` is a `CGFloat` in radians.
- `UIHinge.Status` has `closed`, `partiallyOpen`, `fullyOpen`, and `unknown`. `fullyOpen` means “open as far as the device allows.”
- Apple says the rate and granularity of angle updates are system policy and can change. Apps must not depend on a particular update frequency or precision.
- A nil hinge means the device or view hierarchy is not providing hinge updates. Apple’s Tech Talk treats that as a device without a hinge.
- The app changes size and can move between the outer and inner displays as the phone folds and unfolds. The inner display ignores supported interface orientations.
- The fold appears to layout as a `.division` reserved region, active while partially folded.
- Device Hub’s iPhone Duo simulator can fold to any angle: hold Option and drag the slider under the bezel.

Not published by Apple, and therefore not assumed:

- The numeric range of the hinge angle. Do not assume 0° closed and 180° flat.
- Whether the hinge rests at every angle or only some.
- Whether angle updates arrive while the phone is closed and the app is on the outer display.
- The angle at which the status changes, and whether that point is the same when opening and closing.
- Update rate and precision on hardware.

## 4. Users and context

One player holding the phone with both hands. They fold it slowly, look at the display, and adjust. Sessions are short: a few rounds, under a minute each. They may play while seated, or with the phone on a table in a tent or book pose.

## 5. Core loop

1. The game shows a target, for example “73°”.
2. The player folds the phone. A meter shows how close they are.
3. When the hinge angle stays within the tolerance of the target for the hold time, the round is a match.
4. The game shows the result: error in degrees, time taken, and score.
5. The next round starts with a new target.

A run is five rounds by default. The run score is the sum of the round scores.

## 6. Functional requirements

### 6.1 Hinge reading

- R1. The app reads the hinge angle through `onHingeChange` and stores the latest reading in degrees with a timestamp.
- R2. It reads the angle whenever `hinge` is non-nil, in every status. It must not copy the Tech Talk sample’s rule of reading only while partially open, because targets near the ends would then be impossible.
- R3. The pose shown to the player comes from `status`, never from cutting the angle into ranges.
- R4. Readings with status `unknown` are shown as “Can’t read the hinge” and do not count toward a match.
- R5. If the app has not received a reading recently, it shows “Waiting for the hinge” instead of a stale value. The stale threshold is a tuning constant.

### 6.2 Calibration

Because Apple does not publish the range, the app measures it on each phone.

- R6. On first launch, the app asks the player to close the phone fully, then open it flat. It records the lowest and highest angles seen and the angles at which `status` reported `closed` and `fullyOpen`.
- R7. The playable range is the recorded range minus a margin at each end, so targets do not sit on the end stops or on a status change.
- R8. If the recorded range is too narrow to play, calibration fails with an explanation and a retry.
- R9. Calibration is stored on the device and can be redone from settings.
- R10. If no reading arrives while the phone is closed, calibration does not block. The low end is the lowest angle seen while open.

### 6.3 Targets

- R11. Targets are whole degrees chosen uniformly inside the playable range.
- R12. Consecutive targets differ by at least a minimum distance, so a round does not start already matched.
- R13. A round does not start until the current reading is outside the tolerance window.

### 6.4 Matching and scoring

- R14. A round is matched when every reading for at least the hold time is within the tolerance of the target. The timer is based on timestamps, not on how many updates arrived.
- R15. If the hinge is held still, updates may stop arriving. A held still reading with no new update still counts as being in the window. Leaving the window resets the hold timer.
- R16. Score per round rewards a small final error and a short time. The exact formula is a tuning decision. It must be monotonic in both.
- R17. A round times out after a limit and scores zero.
- R18. Default tolerance and hold time are tuning constants, set after measuring the hardware. Easy, normal, and hard change only those two constants.

### 6.5 Feedback

- R19. A meter shows distance to the target, for example warmer and colder. A “hidden” setting removes the live number so the player plays by feel.
- R20. A match triggers a haptic and a short sound. Sound respects the silent switch.

### 6.6 Displays and layout

- R21. Game state lives above the view that the system replaces when the app moves between displays. A fold mid-round must not reset the round.
- R22. Text and controls stay inside the safe area and off the fold’s reserved region.
- R23. Layout is driven by available width and height, not by device model or interface orientation.
- R24. The game works in Split View on the inner display, at reduced size.

### 6.7 No hinge

- R25. If `hinge` is nil, the app shows a screen saying the game needs iPhone Duo. It does not crash and does not quit itself.
- R26. The App Store description states the iPhone Duo requirement clearly.

### 6.8 Persistence

- R27. Best run score and calibration are stored on the device. No network.

## 7. Screens

- Home: Play, best score, settings.
- Calibration: two steps, close then open flat, with a live readout.
- Round: target, meter, round number, timer.
- Result: per-round error and time, run total, Play again.
- Settings: difficulty, hidden mode, sound, recalibrate.
- No hinge: explanation only.

## 8. Success criteria

- On the iPhone Duo simulator, a full run can be played with the Option-drag hinge slider.
- On hardware, a player can match targets across the whole playable range, including the lowest and highest.
- A fold during a round never resets the round or loses the score.
- Opening the app on an iPhone without a hinge shows the no-hinge screen.
- The scoring logic is covered by unit tests that do not need a device.

## 9. Risks

| Risk | Effect | Response |
| --- | --- | --- |
| Hinge range differs from 0–180 | Wrong or unreachable targets | Calibrate on every phone (R6–R10) |
| Updates coarse, slow, or stop when still | Matches feel random | Tolerance plus timestamp hold (R14–R15) |
| Hinge does not rest at some angles | Some targets impossible | Measure on hardware; widen tolerance or drop those targets |
| No readings while closed | Low end of range missing | Calibrate from open readings (R10) |
| Status flips at different angles opening and closing | Pose label jumps | Show pose from `status`; never match on status |
| App moves displays mid-round | Lost state | Keep state above the replaced view (R21) |
| Installed on other iPhones | One-star reviews | No-hinge screen and clear listing (R25–R26) |
| App Review treats a hinge-only app as incomplete | Rejection | Unknown; prepare the no-hinge screen and listing text |
| Only simulator testing before 23 October | Behavior differs on hardware | Hardware test pass before submission |

## 10. Milestones

1. Hinge probe: a screen that logs angle, status, and timestamps. Run on the simulator to measure range and update behavior.
2. Core loop: targets, matching, scoring, with unit tests.
3. Calibration.
4. Feedback and layout across displays and Split View.
5. Hardware pass after 23 October: tune tolerance, hold time, and margins.
6. App Store submission with iPhone Duo screenshots.

## 11. Open questions

- What range, update rate, and precision does the hardware report?
- Does the hinge stay at any angle, or settle to detents?
- Is the hinge readable while closed?
- Will App Review accept an app that is not playable without a hinge?
- Final scoring formula and difficulty constants.
