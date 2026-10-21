# Native game simulator validation — 19 October 2026

Source: recorded native UI testing with genuine Device Hub Option-drag hinge controls, iPhone Duo simulator, iOS 27.1 (24A94425), Xcode 27.1 (27A9275). These are simulator observations, not hardware measurements.

## Verdict: partial validation

Calibration, five-round progression, stationary-hold matching, result totals, and local persistence were exercised. A complete run with five successful matches was **not** demonstrated. In the focused follow-up, the first round of each run timed out while positioning simulator controls; the other eight rounds matched on Easy (±6°, 0.7 seconds). Those setup/deadline limitations are not demonstrated game-logic failures.

## Calibration and persistence

- Fresh game installation required calibration; the separate diagnostic probe was left intact.
- No-movement calibration at 0°–0° failed and retry worked.
- Observed simulator endpoints 0°–180° produced a saved playable range of 8°–172° after margins. Relaunch retained it. This does not establish a hardware range.
- Completed-run results, best score, and settings survived relaunch. Play Again restarted round 01. Hidden-angle mode removed the live number while retaining the target and meters.
- The first pass exposed an offscreen fresh-reading warning. The game now presents a system alert immediately instead. The follow-up confirmed the alert after 32 seconds still, dismissal with OK, and successful start after real hinge movement.

## Matching results

The first Normal run had four timeouts and one match: target 72°, final error 0.6°, elapsed 14.6 seconds, score 473. Summary and restored results totaled 473.

Focused follow-up on Easy:

| Run | Target | Final error | Points |
| --- | ---: | ---: | ---: |
| 1 | 21° | 3.3° | 393 |
| 1 | 101° | 3.3° | 550 |
| 1 | 68° | 2.1° | 545 |
| 1 | 169° | 0.4° | 728 |
| 2 | 31° | 3.6° | 530 |
| 2 | 163° | 2.8° | 568 |
| 2 | 125° | 1.1° | 664 |
| 2 | 152° | 0.4° | 667 |

Each run also contained one initial timeout scoring zero. Summaries correctly totaled 2216 and 2429; the best score became 2429. Original Normal difficulty was restored afterward. No source tuning or sensor injection was used.

## Display caveat and remaining gaps

The first pass reproduced a black intermediate simulator surface during round 3; closing restored the visible game. The cause is unresolved. A similar symptom occurred in the diagnostic probe. It did not recur in the follow-up; this does not prove it is fixed.

Active closed→partial and separate closed→fully-open checks retained round and target. Actual root replacement, reduced-size/Split View, background-time exclusion, nil-hinge recovery, missing-final-closed-callback calibration, Hard matching, and a stale Next Round request were not independently validated in this UI pass. Physical haptics, audio/Silent-switch behavior, hardware range, precision, comfort, and detents remain untested.

Shell verification: 22 core tests, strict Swift-format lint, and both native simulator builds passed. The alert-only change was linted and rebuilt afterward.
