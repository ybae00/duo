# Duo — Minimal Prototype Requirements

Status: 21 October 2026. These rules replace the earlier timed, scored, five-round prototype. Nothing here has been validated on physical hardware.

Build instructions: [agent.md](agent.md).

## 1. Goal

Test one simple interaction: see a target angle, fold the phone by feel, and choose when to reveal the actual angle. Add features only after this interaction is useful and enjoyable.

Duo is a native Swift/SwiftUI app for iPhone Duo and iOS 27.1. The physical hinge is the only source of angle input. Start and Done are explicit button actions.

## 2. Minimal loop

1. The ready screen has one button: **Start**.
2. Start chooses and displays a whole-degree target within the calibrated playable range.
3. The player folds the phone for as long as they want. Show no live angle, warmer/colder meter, countdown, points, or hold progress.
4. The guessing screen has a **Done** action (duplicated on the two edges of inner layouts for reachability). Reaching the target never completes the guess automatically.
5. Done snapshots the latest valid hinge angle. Display the actual angle next to the target, or toggle to the closeness percentage out of 100%.
6. The result stays frozen even if the player moves the hinge. Its **Done** action returns to the Start screen without generating another target; only Start begins another independent guess.

There is no time limit, scoring, tolerance requirement, hold duration, difficulty, fixed round count, run summary, history screen, settings screen, or sound/haptic feedback in this version. A new random target may equal a previous target; no spacing rule is needed.

## 3. Result percentage

The alternate result view shows closeness to the target, not a point score. Calculate from the unrounded actual angle:

\[
\text{closeness} = 100 \times \max\!\left(0, 1 - \frac{|\text{actual} - \text{target}|}{|\text{target}|}\right)
\]

For example, target 50° and actual 49° gives **98% / 100%**. Target 90° and actual 81° (or 99°) gives 90% / 100%; an exact guess gives 100% / 100%. Cap at 0% for a miss larger than the target magnitude.

Show the actual angle to one decimal place and the closeness percentage rounded to a whole percent. A target of zero has undefined relative closeness unless the actual angle is also zero: disable the percentage toggle for an inexact zero-target guess, or show 100% for an exact zero. Do not assume calibration can never include zero or negative angles. The result begins in degrees and the toggle offers **View in percentage** / **View in degrees**.

## 4. Necessary hinge setup

Apple does not publish the numeric hinge range; never assume 0°–180° on hardware.

- On first use, Start opens a two-step setup: close fully → Next → open flat → Start. Only setup shows a live angle.
- Collect observed readings and trim provisional 8° margins at both ends. Require at least a provisional 40° playable span.
- Completion saves the range locally and starts the first guess.
- Missing a final callback while fully closed must not block setup. Use the lowest valid observed reading.
- If the range is too small or readings are missing, explain and offer retry.
- Later launches reuse the saved range. A recalibration settings screen is deferred with other extras.

These numbers are provisional until hardware testing.

## 5. Hinge validity and lifecycle

- Attach SwiftUI `onHingeChange` at the root. Read `DeviceHinge.angle.degrees` whenever the hinge exists, regardless of status.
- Map pose from Apple's status, never from angle thresholds. Unknown status or invalid numbers cannot be submitted.
- Stillness may produce no callbacks. Retain the latest valid reading indefinitely while the app remains active with an available hinge context; lack of callbacks is not a gameplay deadline.
- A nil hinge, invalid reading, or inactive scene invalidates the retained reading. Require a new valid callback before Done can submit after an interruption, without changing the target.
- Keep a five-second initial context grace period before showing a no-hinge explanation and Retry. This is availability handling, not a guess time limit.
- A Done request without a valid reading shows an immediate alert and keeps the current guess.
- Do not infer angles with accelerometer/gyroscope data. Silent delivery interruptions cannot be distinguished from stillness by elapsed time alone; reliability remains a hardware-validation question.

## 6. State, layout, and storage

- `DuoApp` owns `GameModel` above replaceable views; `GuessSession` in `DuoCore` owns the manual guess state and frozen result.
- Size from the available view geometry and safe area. Keep the main content off active `.division` reserved regions. No device-model, orientation, or `UIScreen.main` layout checks.
- Only calibration is persisted by the minimal app. The current guess/result is in memory and is not restored after terminating the app.
- Previous prototype score/settings keys are left untouched but ignored. No new points or run history are written. No networking.
- Keep `DuoProbe` separate and unchanged. Earlier timed-rule types/tests remain in the package for reference but are not used by the active game.

## 7. Acceptance checks

- Unit tests cover manual-only completion, no hold/deadline, latest-reading submission, frozen results, invalidation/recovery, percentage math including zero, calibrated target selection, and continuing beyond five guesses.
- Core tests, strict Swift-format lint, and both native simulator builds pass.
- The updated Figma screens passed a native iPhone Duo / iOS 27.1 simulator playthrough: fresh calibration, Start → target → genuine hinge movement → Done → both frozen result views → Done → Start again, including both wide/tall Done controls and closed outer submission.
- A 35-second stationary pause did not end the guess; Done still worked afterward. The live angle stayed hidden, folding did not reset the target, and further movement did not change the submitted result. Maximum accessibility text retained complete result values in outer, wide, and tall layouts.
- Prior timed-game recordings are historical evidence, not validation of these new rules. Black surfaces recurred during opening and recovered after releasing fully open; the cause remains unconfirmed.
- Hardware accuracy, range, feel, display transitions, and reduced-size/Split View behavior still need physical-device testing before release.

## 8. Deferred

History, scores, timers, automatic matching, difficulty, feedback, extra modes, accounts, multiplayer, cloud sync, Game Center, ads, purchases, and App Store preparation.
