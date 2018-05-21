# Release Instructions

Some assumptions:

- `master` is the default branch and is production-ready
- commits made to `master` are built and pass in [buddybuild][1]
- all `master` builds are sent to iTunes Connect, with the same buddybuild build number
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

- Update the release notes under `docs/release-notes.md`
  - create a pull request to collaborate and get approval
  - determine the next build number and include it in release notes
  - merge the release notes to `master` branch
  - this will result in a release build matching the build number provided
- Create a tag from `master` matching the format: `major.minor.build`
  - for example: `1.0.1189`
  - push the tag to GitHub and create a corresponding "Release" on GitHub.com
  - copy the release notes to the "Release" on GitHub
  - download the `.ipa` from buddybuild and attach it to the Release on GitHub
- Hopefully by now the build has been uploaded to iTunes Connect
- Browse to iTunes Connect and continue the "Distributing..." instructions

## Distributing Builds through TestFlight (release)

_all `master` branch builds are automatically uploaded from buddybuild_

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

---

[1]: https://dashboard.buddybuild.com/apps/5a0ddb736e19370001034f85
[2]: https://developer.apple.com/testflight/testers/
[3]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270/testflight?section=iosbuilds
[4]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270
