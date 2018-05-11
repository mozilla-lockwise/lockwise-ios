# Test Plan

_Test plan for [Firefox Lockbox for iOS][1]_

## Overview

Firefox Lockbox for iOS is a new mobile iOS app developed with a pre-defined set of P1 "must have" requirements and a target release at the end of June in the Apple App Store and in Test Pilot.

Mozilla Product Integrity provides embedded QA to work with the team throughout the weekly sprints allowing for ongoing testing and feedback, issue triage, and continuous test plan development and end-to-end regression testing in order to accommodate a quick release schedule and submission to the App Store by end of May.

### Ownership

* Product Integrity: Catalin Suciu, Simion Basca, Isabel Rios
* Product Manager: Sandy Sage
* Engineering Manager: Devin Reams
* Engineering Leads: Sasha Heinen, James Hugman, Matt Miller

### Entry Criteria

* PI has access to all product documentation, designs, code
* The iOS app code is available on GitHub and builds:
  - locally via Xcode (Branch and Release)
  - on device via buddybuild (Branch and Release)
  - on device via TestFlight (Release)
  
### Exit Criteria

* All test suites against P1 "must have" features have performed
* All bugs related to the P1 "must have" features have been triaged
* All bugs resolved fixed have been verified

## Test Matrix

- Devices to be tested (no iPad):
  - iPhone X
  - iPhone 8 and 8 Plus
  - iPhone 7 and 7 Plus
  - iPhone SE
- Major operating system versions to be tested (current and one prior):
  - iOS 11 (including point-release betas)
  - iOS 10

## Test Suites

- Documented in TestRail: [https://testrail.stage.mozaws.net/index.php?/projects/overview/52][2] (internal Mozilla tool)
- Performed twice-weekly
- Covers all [P1 "must have" Requirements][3] (internal Mozilla document)
  - 01 Sign in to Sync
  - 02 Onboarding
  - 03 Access saved entries
  - 04 No entries support
  - 05 Biometrics to lock/unlock
  - 06 View entry
  - 07 Copy / paste retrieval
  - 08 View password
  - 09 Account management
  - 10 Support
  
### Out of Scope

1. Internal [metrics/analytics][4] review and testing (see [metrics.md][5])
2. Internal [security review][6] (performed separately)

---

[1]: https://github.com/mozilla-lockbox/lockbox-ios
[2]: https://testrail.stage.mozaws.net/index.php?/projects/overview/52
[3]: https://docs.google.com/document/d/1q2xYGsoB0ylfir-Bkg8BwP4Aj1H6OjjJHW2FmX-JexU/edit#
[4]: https://github.com/mozilla-lockbox/lockbox-ios/issues/202
[5]: /metrics.md 
[6]: https://github.com/mozilla-lockbox/lockbox-ios/issues/51
