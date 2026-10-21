# duo

A native iPhone game for iPhone Duo. The player folds the phone to match a prompted hinge angle.

- [Product requirements](docs/prd.md)
- [Build guide for agents](docs/agent.md)

## Minimal playable prototype: Start → Done

`Duo/Duo.xcodeproj` is the native game, separate from the unchanged diagnostic probe below. Its iOS 27.1 target and local `DuoCore` dependency were created in Xcode 27.1.

**Start → target → fold by feel → Done → actual angle vs. target → Start again.**

The ready/result screens have one Start button; the guessing screen has one Done button. There is no countdown, point score, automatic matching, hold requirement, live-angle hint, difficulty, five-round run, settings, or history screen.

Results show the actual angle, the target, and a small **% off** beside the actual angle. Percentage off is absolute error divided by the absolute target, multiplied by 100. Target 90° and actual 81° gives 10.0% off; an exact guess gives 0.0% off. Zero-target relative error is shown as a dash unless the guess is exactly zero. Results stay frozen while the phone moves.

On first use, Start opens a one-time calibration: close fully → Continue → open flat → Start. Setup alone shows the live angle. The observed range has provisional margins and an insufficient range offers retry; no hardware 0°–180° range is assumed. Calibration is saved in `UserDefaults` and reused on later launches. Current guesses/results are not restored after app termination. Old score/settings data is preserved but ignored.

`DuoApp` owns `GameModel` above replaceable views. The headless `GuessSession` accepts a result only when Done is pressed. There is no gameplay clock or reading-age deadline: a stationary reading remains usable while active. A nil/unknown/invalid hinge reading or scene inactivity clears it; recovery needs a new valid callback without resetting the target. Missing readings show an immediate alert on Done. A one-shot five-second first-context wait precedes the no-hinge screen; it does not limit a guess.

Compile/type-check and lint without launching the game:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer
xcrun swift test --package-path DuoCore
xcrun swift-format lint --strict --recursive DuoCore/Sources DuoCore/Tests DuoProbe/DuoProbe Duo/Duo
xcodebuild -project Duo/Duo.xcodeproj -scheme Duo \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

The [recorded manual-flow simulator test](internal/manual-guess-simulator-2026-10-19.md) passed Start → Done, a 53-second stationary pause, percentage calculations, frozen results, background recovery, and calibration reuse after relaunch. Fresh calibration in the new UI, zero/invalid-reading presentation, hardware, and Split View remain unverified. Earlier [timed-game simulator results](internal/game-simulator-2026-10-19.md) are historical. The prior intermittent black display did not recur, but its cause remains unresolved.

## Milestone 1: hinge probe

`DuoProbe/DuoProbe.xcodeproj` is a native SwiftUI measurement app, not the game. It requires Xcode 27.1 and iOS 27.1. The project and its deployment setting were created in Xcode.

Open the project in Xcode 27.1, install its iOS 27.1 simulator runtime, select iPhone Duo in Device Hub, and run. Exercise the Closed, Partially Open, and Open controls, then Option-drag the hinge slider slowly in both directions and click points on it. Use the phase selector and state markers to label observations. Compare the run ID and marker count before and after folding.

Each callback (including a nil hinge) is recorded as JSONL in the simulator app's Documents directory and printed with the `DUO_PROBE` prefix. Records contain wall-clock time, monotonic elapsed time, angle, status, callback number, phase, and marker count. Only records with `kind == "hinge"` are sensor callbacks; lifecycle and marker records are not. Measurements are simulator-only, not hardware guarantees.

Compile/type-check without a running simulator:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer
xcodebuild -project DuoProbe/DuoProbe.xcodeproj -scheme DuoProbe \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcrun swift-format lint --strict --recursive DuoProbe/DuoProbe
```

To retrieve logs after a simulator run:

```sh
xcrun simctl get_app_container <simulator-UDID> dev.ybae00.DuoProbe data
```

Look in the returned container's `Documents` directory. The probe remains a measurement app, not the game.

[Simulator measurements and limitations (19 October 2026)](internal/hinge-probe-simulator-2026-10-19.md)

## Headless rules and historical timed prototype

`DuoCore/` is a local Swift package linked to the probe's Xcode target to verify iOS compatibility; the probe does not yet invoke it. It contains calibration, whole-degree target selection, the active manual `GuessSession`, and unit tests. Earlier clock-driven matching, scoring, and difficulty types are retained for reference, not used by the minimal app. Hinge status must be mapped into `Pose` at the app boundary; the core never infers pose from the angle.

Run the tests without a simulator:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.1.app/Contents/Developer
xcrun swift test --package-path DuoCore
xcrun swift-format lint --strict --recursive DuoCore/Sources DuoCore/Tests DuoProbe/DuoProbe
```

The active `GuessSession` has no tick, timeout, tolerance, or score. Its result changes only on manual submission. Legacy `MatchJudge`/`RunEngine` tests still verify the earlier prototype, but passing them does not mean the new UI has been exercised. Use the separate `Duo` app for the native flow.
