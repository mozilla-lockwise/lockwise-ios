# Release Instructions

Some assumptions:

- `master` is the default branch and is production-ready
- commits made to `master` are built and pass in [buddybuild][1]
- `production` is our public release branch and may not match `master`
  - ideally, `production` will perfectly reproduce master
  - but if `master` is in an un-releasable state, we cherry-pick commits to this branch
  - this is an exception rather than the preferred maintenance method
- all `master` and `production` builds are sent to iTunes Connect, with the same buddybuild build number
- iTunes Connect has ["internal" testers][2] (mobile devs, product integrity)
  - thus, iTunes Connect and TestFlight can have ["external" testers][2] which we add manually
  - currently, no plans exist for "external" users to include anyone outside of Mozilla

## Distributing Builds through buddybuild (branch / release)

_all commits on all branches and pull requests are automatically built_

1. Push to the git branch available on GitHub.com and open a pull request
2. Open [buddybuild][1] from a mobile device and browse to the build
3. Alternatively, add an email address to the "Deployments" email list(s)
  - this is expected to be a small group of contributors and Mozillians

## Preparing a Release (for TestFlight or App Store)

1. Update the release notes under `docs/release-notes.md`
  - create a pull request to collaborate and get approval
  - determine the next build number and include it in release notes
  - merge the release notes to `master` branch
  - this will result in a release build matching the build number provided
2. Create and merge a pull request _from_ `master` _to_ `production` so it tracks the release
  - https://github.com/mozilla-lockbox/lockbox-ios/compare/production...master
3. Create a tag from `production` matching the format: `major.minor.patch.build`
  - for example: `1.2.1399` is major version 1.2, (buddybuild) build 1399
  - for example: `1.3.1.1624` is major version 1.3 with 1 patch release, (buddybuild) build 1624
4. push the tag to GitHub and create a corresponding "Release" on GitHub.com
  - copy the release notes to the "Release" on GitHub
  - download the `.ipa` from buddybuild and attach it to the Release on GitHub
5. Hopefully by now the build has been uploaded to iTunes Connect
6. Browse to iTunes Connect and continue the "Distributing..." instructions

### In Case of Emergency (Release)

_similar to above, but requires explicit cherry-pick commits on `production` branch when `master` branch is not in a release-able state_

1. Merge the emergency changes or fixes or features to default `master` branch as usual
2. Update the release notes
3. Create and merge a pull request _up to and including_ the last release-able commit on `master` to `production`
4. Then `git cherry-pick` each additional commit from `master` to be included in the release
  - thus skipping or avoiding the non-release-able commits
5. Push the resulting `production` branch to GitHub.com
6. Create a tag from `production` matching the format: `major.minor.patch.build`
  - for example: `1.3.1.1624`
7. Push the tag to GitHub and create a corresponding "Release" on GitHub.com
  - copy the release notes to the "Release" on GitHub
8. Browse to buddybuild and find the desired `production` branch build to distribute
  - download the `.ipa` from buddybuild and attach it to the Release on GitHub
9. From the buddybuild's build "Deploy" tab, select the "Upload to iTunes Connect" link
10. Browse to iTunes Connect to find the build and continue the "Distributing..." instructions

## Distributing Builds through TestFlight (release)

_all `master` and `production` branch builds are automatically uploaded from buddybuild to iTunes Connect_

1. Browse to [TestFlight > Builds > iOS][3] in iTunes Connect
2. Find the desired build number to distribute
3. Provide [export compliance responses](export-compliance.md)
  - this makes the build immediately available to "internal" iTunes Connect users
4. Copy the release notes for this release and add them to the "Test Details"
5. Add at least one other "Group" of "external" testers to the build
  - after review, this will make it available for all those "external" testers
  - example: "lockbox-dev" which includes our other non-iTunes Connect engineers
  - example: "Product" which includes other product and content Mozillians
  - example: "Cohort A" which includes the first round of volunteers to test

## Distributing through the App Store (release)

1. Browse to the [App Store][4] section in iTunes Connect
2. Confirm the "App Information" details are accurate and complete
3. Confirm the "Pricing and Availability" details are accurate and complete
4. Browse to the "iOS App" section to "Prepare for Submission"
  - provide the version information (keywords, URLs, promotional screenshots)
  - select the corresponding build number for the App Store release
  - set the release instructions (manually, immediately, on a date)
5. Save and "Submit for Review"
6. ???

## Taking screenshots for new releases

Screenshots are automated via Fastlane. To get Fastlane, run `brew cask install fastlane`. From there, you will be able to run `fastlane snapshot` in the root directory of the project to run the screenshot task.

Configuration:
- [languages] Update / add desired locales to `fastlane/Snapfile`
- [devices] Update / add desired device sizes to `fastlane/Snapfile`
- [text size][5] Update the `CONTENT_SIZE` variable in `LockboxXCUITests/BaseTestCase.swift`

## Updating the version for a release

- Once a version has been merged or released, the app version should be bumped
- Update the value in `Common/Resources/Info.plist`, for example from `1.2` to `1.3`

---

[1]: https://dashboard.buddybuild.com/apps/5a0ddb736e19370001034f85
[2]: https://developer.apple.com/testflight/testers/
[3]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270/testflight?section=iosbuilds
[4]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270
[5]: https://stackoverflow.com/questions/38316591/how-to-test-dynamic-type-larger-font-sizes-in-ios-simulator
