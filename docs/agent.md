# agent.md — building Duo

Read this before writing code for Duo. The product spec is [prd.md](prd.md). The platform research notes are kept outside this repository.

Duo is a native iPhone game. It shows a target angle, and the player folds iPhone Duo until the hinge matches it. The hinge is the only input.

## 1. Ground rules

1. **Native only.** Swift and SwiftUI, Xcode 27.1, iOS 27.1 SDK. No web app, PWA, React Native, Flutter, Capacitor, or web view wrapper. Safari has no hinge angle.
2. **Do not invent APIs.** Every Apple symbol you use must appear in Apple’s documentation. Appending `.md` to a `developer.apple.com/documentation/...` URL returns readable text. If you cannot find a symbol, say so and stop; do not guess a name.
3. **Mark what you did not verify.** If code was not compiled, say “not compiled.” If behavior was only seen in the simulator, say so.
4. **Do not assume 0° to 180°.** Apple does not publish the hinge range. Use calibration (PRD R6–R10).
5. **Do not depend on update rate or precision.** Apple says both are system policy. Never match on an exact degree or count updates as time.
6. **Read the angle in every status.** Do not copy the Tech Talk sample that reads the angle only when `status == .partiallyOpen`.
7. **Do not derive the pose from the angle.** Use `status` for the pose and the angle for gameplay.
8. **Do not use `UIScreen.main`, device model, idiom, or interface orientation for layout.** Size from the view.
9. **Do not use the accelerometer or gyro to estimate the fold.**
10. **Do not hand-edit `project.pbxproj`.** Create and change the Xcode project in Xcode on a Mac.

## 2. Environment caveats

- The current cloud environment is Linux. There is no Xcode, no Swift toolchain, no iOS SDK, and no simulator. Nothing that imports SwiftUI or UIKit can be built or run here.
- From Linux, an agent can write Swift sources and documentation. It cannot prove they compile against the iOS 27.1 SDK.
- The game logic can be a Swift package with no Apple UI imports. That package can be tested with `swift test` on Linux if a Swift toolchain is installed. No toolchain is installed now, and that path has not been tried.
- Real builds, simulator runs, signing, and submission need a Mac with Xcode 27.1. The macOS version Xcode 27.1 requires was not checked.
- This repository holds the product spec and this guide. It does not yet contain the Xcode project.

## 3. Verified API surface

Use only these for the hinge and fold. Each was read in Apple’s documentation on 19 October 2026.

| Symbol | What it is |
| --- | --- |
| `View.onHingeChange(isEnabled: Bool = true, _ action: (DeviceHingeContext, DeviceHingeContext) -> Void)` | SwiftUI. Called with the previous and current context. |
| `DeviceHingeContext.hinge: DeviceHinge?` | Current hinge, or nil. |
| `DeviceHinge.angle: Angle` | Current angle. Read `.degrees`. |
| `DeviceHinge.status: DeviceHinge.Status` | Current status. `Status` is documented as a **struct**, not an enum. |
| `UIHingeInteraction(updateHandler:)` | UIKit. Add to a view with `addInteraction`. Has `isEnabled`. |
| `UIHingeInteraction.Update.hinge: UIHinge?` | Nil when the interaction leaves a hierarchy that provides hinge updates. |
| `UIHinge.angle: CGFloat` | Radians. |
| `UIHinge.Status` | Enum: `closed`, `partiallyOpen`, `fullyOpen`, `unknown`. |
| `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)` | SwiftUI reserved regions. Kinds `.occlusion` and `.division`. Option `.includeInactive`. |
| `UIView.reservedRegions(kind:options:)` | UIKit reserved regions. |

Caveats on this table:

- Only `.partiallyOpen` is shown for the SwiftUI `DeviceHinge.Status` in Apple’s sample code. The other SwiftUI status names were not confirmed. Check `DeviceHinge.Status` in the iOS 27.1 SDK before using `.closed` or `.fullyOpen` in SwiftUI. Because `Status` is a struct, compare with `==`; a `switch` may need a `default` case.
- `onHingeChange` documentation shows the modifier as `View/onHingeChange(_:)` in one place and `onHingeChange(isEnabled:_:)` in another. Trust what Xcode autocompletes.
- Whether `onHingeChange` fires once immediately with the current state, or only on change, is not documented. Do not rely on either.

## 4. Architecture

Keep hinge reading, game rules, and UI apart so the rules can be tested without a device.

```
Duo (Xcode iOS app target)
├── DuoApp.swift          App entry. Owns the GameModel.
├── HingeBridge.swift     Converts DeviceHingeContext into HingeReading.
├── GameModel.swift       Observable state for the UI. Forwards readings and ticks to the engine.
├── Views/                Home, Calibration, Round, Result, Settings, NoHinge
└── DuoCore (Swift package, no SwiftUI or UIKit)
    ├── HingeReading.swift
    ├── Calibration.swift
    ├── TargetPicker.swift
    ├── MatchJudge.swift
    ├── Scoring.swift
    └── Tests/
```

### Core types (in `DuoCore`)

- `HingeReading`: `degrees: Double`, `pose: Pose`, `time: TimeInterval`. `Pose` is the game’s own enum: `closed`, `partial`, `open`, `unknown`. Mapping from Apple’s status happens only in `HingeBridge`.
- `Calibration`: collects readings during the two calibration steps. Produces `PlayableRange` (low, high) or a failure reason. Applies the end margins.
- `TargetPicker`: picks whole-degree targets inside `PlayableRange`, at least a minimum distance from the previous target and from the current reading. Takes an injected random source so tests are deterministic.
- `MatchJudge`: holds the target, tolerance, and hold time. Accepts `ingest(_ reading:)` and `tick(now:)`. Returns `searching`, `holding(since:)`, `matched(error:time:)`, or `timedOut`.
- `Scoring`: pure function from final error and elapsed time to points. Monotonic in both.
- `Tuning`: tolerance, hold time, end margin, minimum target distance, round time limit, and stale-reading limit, per difficulty. All values are placeholders until hardware testing.

### Why the judge needs `tick`

Updates may slow or stop while the hinge is still. If the judge only ran when an update arrived, a player holding the right angle might never be scored. So the UI drives `tick(now:)` on a clock, for example a SwiftUI `TimelineView` or a repeating task, and the judge treats the latest reading as still valid until it is older than the stale limit.

### Where the hinge is read

Attach `onHingeChange` to the root view in `DuoApp`, and keep `GameModel` owned by the `App`, not by a screen. When the phone folds, the app can move between displays and its views can be rebuilt. State owned above them survives.

Whether a fold keeps the same scene or creates a new one is not documented. Test it in the simulator. If the scene is replaced, state still has to survive, so do not keep game state in `@State` inside a screen.

### Sketch (not compiled)

```swift
@main
struct DuoApp: App {
    @State private var model = GameModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .onHingeChange { _, context in
                    model.receive(HingeBridge.reading(from: context.hinge, at: .now))
                }
        }
    }
}

enum HingeBridge {
    static func reading(from hinge: DeviceHinge?, at date: Date) -> HingeReading? {
        guard let hinge else { return nil }
        return HingeReading(
            degrees: hinge.angle.degrees,
            pose: pose(for: hinge.status),
            time: date.timeIntervalSinceReferenceDate
        )
    }

    static func pose(for status: DeviceHinge.Status) -> Pose {
        if status == .partiallyOpen { return .partial }
        // Confirm the other SwiftUI status names in the iOS 27.1 SDK before adding them.
        return .unknown
    }
}
```

A nil reading means no hinge. `GameModel` shows the no-hinge screen only after the app has had a chance to receive a first update, so a slow first callback does not flash that screen on iPhone Duo. How long to wait is a tuning value.

## 5. Build plan

Do the milestones in order. Each has a check that must pass before the next.

### Milestone 1 — hinge probe

Goal: learn what the simulator reports before designing numbers.

1. On a Mac, create an iOS App project in Xcode 27.1: SwiftUI interface, Swift language, deployment target iOS 27.1.
2. Add `onHingeChange` to the root view. Log degrees, status, and time for every callback, and show the latest values on screen.
3. Run on the iPhone Duo simulator in Device Hub.
4. Use the Closed, Partially Open, and Open buttons. Then hold Option and drag the slider under the bezel slowly in both directions, and also click points on it.
5. Record in `internal/` (a new report): lowest and highest angle seen, angle at each status change opening and closing, whether readings arrive while closed, how often callbacks arrive while dragging and while still, and whether the app moved displays and kept its state.

Check: the report exists with real numbers from the simulator, labeled as simulator numbers.

### Milestone 2 — core logic

1. Create the `DuoCore` package with the types in section 4. No SwiftUI or UIKit imports.
2. Write unit tests:
   - Target picker stays inside the range, honors minimum distance, and is deterministic with a seeded source.
   - Judge: no match before the hold time; match after a still reading with no further updates; reset when a reading leaves the window; time-out at the limit; stale readings stop counting.
   - Calibration: correct range from a sequence of readings; failure when the range is too narrow; works with no readings while closed.
   - Scoring is monotonic in error and time.
3. Link `DuoCore` from the app target.

Check: all `DuoCore` tests pass.

### Milestone 3 — calibration screen

1. Two steps: close the phone fully, then open it flat. Show the live reading.
2. Feed readings into `Calibration`. Save the result on the device, for example with `@AppStorage` or `UserDefaults`.
3. Offer retry on failure and recalibrate in settings.

Check: on the simulator, calibration completes using the Device Hub controls and survives an app relaunch.

### Milestone 4 — game loop and screens

1. Home, Round, Result, Settings, and No Hinge screens, driven by `GameModel`.
2. Round: show target, meter, timer. Drive `tick(now:)` on a clock.
3. Match: haptic plus sound. Sound respects the silent switch.
4. Hidden mode removes the live degree number. The warmer and colder meter stays.
5. Five rounds per run, then the result screen. Save the best score.

Check: a full run can be played on the simulator with the Option-drag slider, including a target near each end of the playable range.

### Milestone 5 — layout across displays

1. Keep text and controls inside the safe area. Read the `.division` reserved region and keep the target and meter off it.
2. Test closed, open, partially folded, rotated, and Split View on the inner display.
3. Fold and unfold in the middle of a round.

Check: no clipped text, nothing on the crease, and a fold mid-round never resets the round.

### Milestone 6 — hardware pass

Only after 23 October 2026 on a physical iPhone Duo.

1. Repeat the Milestone 1 measurements on hardware and record them next to the simulator numbers.
2. Find out whether the hinge rests at every angle or settles to detents.
3. Tune tolerance, hold time, end margin, and the stale limit per difficulty.
4. Have someone who has not seen the game play a run.

Check: the hardware report exists and every target in the playable range can be matched.

### Milestone 7 — App Store

1. Join the Apple Developer Program and set up signing.
2. In App Store Connect, add iPhone Duo screenshots. Apple shows a Duo badge when they are present, and requires them for submissions from April 2027.
3. State in the description that the game requires iPhone Duo.
4. Submit, and record any App Review response about the hinge requirement.

## 6. Caveats

- **Range.** Calibration replaces any assumed range. Never hardcode 0 or 180.
- **Coarse updates.** Matching uses a tolerance window and timestamps.
- **Stillness.** Updates may stop when the hinge stops. The clock-driven `tick` handles it.
- **Detents.** If the hardware will not rest at some angles, those targets are unfair. Widen tolerance or exclude them after measuring.
- **Readings while closed.** Unknown. Calibration must work without them.
- **Status changes.** They may happen at different angles opening versus closing. Status is for display only.
- **Display moves.** The app may change displays and size in the middle of a round. State must live above the screens.
- **No hinge.** Other iPhones can install the app. They must get a clear screen, not a crash or a broken game.
- **App Review.** Whether a hinge-only game is accepted is unknown.
- **Simulator is not hardware.** Every number before Milestone 6 is a simulator number.
- **No build here.** Code written in the Linux environment is not compiled until someone builds it in Xcode.

## 7. Definition of done for any task

- The change builds in Xcode 27.1 against the iOS 27.1 SDK, or it is clearly labeled “not compiled” with the reason.
- `DuoCore` tests pass.
- No API is used that is missing from Apple’s documentation.
- Any new measurement is written to an `internal/` report with where it came from: simulator or hardware, and the Xcode and iOS versions.
