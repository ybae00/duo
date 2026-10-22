# Figma screens — native simulator validation

Tested the local working tree on 22 October 2026 using Xcode 27.1 and the iPhone Duo / iOS 27.1 simulator. This is simulator evidence, not physical-hardware validation. Normal Duo was used, not the isolated camera probe. Hinge readings came from genuine Option-drag simulator controls, with no injected readings.

## Corrections found during testing

- Wide guessing Done controls initially rendered as short squares. Giving each button its 303-point width before rotation restored the long vertical bars; both controls subsequently submitted in separate guesses.
- Maximum accessibility text initially truncated the actual result. Accessibility sizes now stack the actual and target vertically; normal text keeps the horizontal Figma comparison. Complete readings and both toggle directions passed in outer, inner-wide, and inner-tall layouts.

## Observations

| Check | Result |
| --- | --- |
| Existing calibration | Home visibly rendered before Start; saved range 8°–172° was reused. |
| Fresh calibration | Separate simulator with no preferences entered close setup; observed 0.0° → Next → open setup → 180.0° → Start. Saved range was [8, 172]. Existing simulator data was not deleted. |
| No deadline or automatic completion | Target 152° stayed visible during genuine hinge movement and a 35-second stationary interval. No timer, score, live-angle hint, hold requirement, or automatic completion appeared. |
| Frozen result | Done submitted 106.3° /152°; further movement did not change it. Percentage showed 70% /100%, consistent with closeness, then toggled back to the same degrees. |
| Latest-revision default flow | Start →117° target → hinge drag → Done →133.2° /117° →86% /100% →degrees →Done →Home. Subsequent Start chose 127°. |
| Edge submission | Both wide controls and both tall controls submitted in separate passes. Closed outer Done submitted 0.0° /90° and displayed 0% /100% without reopening. |
| Maximum accessibility text | Wide/tall showed complete 164.8° /127° and 70% /100%; upright outer showed complete 165.4° /78° and 0% /100%. Both toggle directions and result Done remained usable. |
| End state | Default large text restored and wide Foldie Start left foregrounded. |

## Limitations

- Black surfaces recurred during opening drags; releasing fully open restored the app. The cause is undetermined, and continuous Done visibility through display handoff is not guaranteed by these tests.
- Fresh-simulator bootstatus reported a data-migration failure, but installation, launch, rendered setup, and calibration completed.
- Physical hardware, Split View, exhaustive numeric strings and hit-area boundaries, and pixel-exact Figma matching remain unverified.
- Automatic annotated recording export failed repeatedly, including a short follow-up. A playable MP4 was recovered from raw screen-capture segments, but delivery rejects unregistered, unannotated app recordings. The requested video could not be delivered; raw captures remain available for runtime recovery.

Key screenshots are delivered in the [Devin session](https://app.devin.ai/sessions/ae8f1be6f4444935b1604de7d6b700bd). No commits, pushes, PRs, device erase, or changes to normal camera-free gameplay were performed during testing.

## UI sizing and right-side result follow-up

Verified the corrected local normal Duo build with the same Xcode 27.1 / iOS 27.1 simulator, using genuine hinge controls. Start and gameplay now share one action-button implementation. The default button face uses a 17-point semibold system label, 21-point line box, 10-point padding, and 12-point corners; its minimum touch height remains 44 points. Wide result Done is beneath the comparison in the right panel. Parent layout proposals no longer stretch rotated button faces.

- At default `large` text, outer guessing and result buttons each measured 909 × 123 screenshot pixels, or **303 × 41 points**. Wide blue bars measured approximately **41 × 303 points**; final wide black Done measured **303 × 41 points** on the right.
- Both wide edge controls submitted genuine readings in separate guesses. Result Done returned to Start, and a subsequent Start chose another target. The result remained frozen through hinge movement. Taps near the top and bottom of the toggle's 44-point touch area switched views in the first follow-up pass.
- The first maximum-text follow-up exposed a truncated toggle label. The corrected label wraps at accessibility sizes instead of keeping a one-line height. The latest build showed complete 119.1° /97° and 77% /100% in tall and wide layouts, and 0.0° /166° and 0% /100% on the outer display. Both full toggle labels and both directions passed in all three layouts; maximum-text wide and outer Done returned to Start.
- Default `large` text was restored and read back. The latest app was left foregrounded on the inner-wide result **165.2° /115°**, with Done on the right, for live Desktop review.
- All 36 core tests, strict recursive Swift-format lint, and the normal simulator build passed. No gameplay logic or camera-probe behavior changed in this follow-up.

The intermittent black surface recurred during an opening drag and cleared when released fully open. Physical hardware, exact SF Pro/Inter font-metric equivalence, and exhaustive hit-area boundaries remain unverified. The first follow-up's single recording export failed; no further recording/recovery was attempted. Latest screenshots were delivered through the session. Changes remain local, without commits, pushes, or PRs.

## Fast result count-up follow-up

Verified the updated normal Duo build on the same Xcode 27.1 / iOS 27.1 iPhone Duo simulator using genuine hinge input, 60-fps capture frames, and screenshot bursts. These are presentation checks, not hardware validation or changes to the frozen game result.

- The actual number visibly counted from 0.0° through 56.6° to 144.7° in approximately 0.45 seconds. The /83° target stayed static with no visible comparison-layout jitter. Further hinge movement did not alter the settled result.
- The result toggled between 144.7° /83° and 26% /100%. A subsequent submission counted again through 46.9° and 139.6° to 147.6°, with /168° static. Toggling that result to 88% /100% and rotating to portrait did not replay the count.
- With Device Hub Reduce Motion enabled, the first captured result already showed the final 152.7° /71° without counting. Reduce Motion was restored to OFF and confirmed via checkbox readback.
- Maximum accessibility text retained complete result values, both toggle labels, and reachable Done. Default `large` text was restored and read back; the app was left on the wide 147.6° /168° result with Done on the right.
- All 36 core tests, strict recursive Swift-format lint, and the normal simulator build passed before this runtime check.

Recording post-processing failed again; animation frames and screenshots were used instead of a delivered video. Final VoiceOver-label semantics remain unverified because the accessibility bridge selected an unrelated simulator despite requesting Duo. Physical hardware and exhaustive numeric/layout combinations remain untested. The original checkout's camera experiment is excluded from the UI PR.
