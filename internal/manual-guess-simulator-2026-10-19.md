# Manual Start → Done simulator validation — 19 October 2026

## Verdict

Passed the focused native manual-guess flow using genuine Device Hub Option-drag hinge controls on iPhone Duo, iOS 27.1 (24A94425), Xcode 27.1. These are simulator observations, not hardware validation. No source, tuning, injected readings, probe, or preferences were changed by the test.

## Observations

- Ready showed a single Start action. Saved 8°–172° calibration was reused without setup.
- Start displayed target 133° and Done only. No live angle, meter, timer, points, settings, or round count appeared.
- After hinge movement, a measured 53.16-second stationary interval (including an explicit 36-second wait) left the same guess active. Done accepted it without a stale-reading alert.
- That submission showed target 133°, actual 111.4°, and 16.2% off. Relative error calculated from the displayed values is approximately 16.24%, consistent with rounding.
- Moving from partially folded to fully open left the result frozen at 133° / 111.4° / 16.2% off.
- Start began an independent guess. A deliberately distant submission showed 43° / 180.0° / 318.6% off, consistent with 318.6047% relative error. No tolerance gate or points prevented submission.
- After backgrounding and returning, waiting/no-hinge UI required genuine movement. Movement recovered the same 142° target; Done showed 150.9° / 6.2% off, consistent with unrounded-reading and display-rounding bounds.
- Termination/relaunch returned to ready, not the previous result. Start chose 121° without repeating calibration.
- Read-only preferences snapshots were identical before and after, including calibration and legacy score/settings/result keys.
- The earlier black simulator surface did not recur. Its cause remains unresolved; this run does not establish that it is fixed.

## Coverage gaps

Fresh calibration in the new UI, zero-target presentation, unknown/invalid-reading UI, statistical randomness, Split View, and physical-device behavior were not tested. Core tests cover zero-target math and invalid-reading state handling, but do not replace native UI or hardware validation. No new dependencies, services, or blueprint changes were needed.

The recorded evidence is attached to [the Devin session](https://app.devin.ai/sessions/ae8f1be6f4444935b1604de7d6b700bd). Earlier timed-game recordings remain historical and do not validate this version.
