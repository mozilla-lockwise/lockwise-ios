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

## Distributing Builds through TestFlight (release)

_all `master` branch builds are automatically uploaded from buddybuild_

1. Browse to [TestFlight > Builds > iOS][3]
2. Find the desired build number to distribute
3. Provide [export compliance responses](export-compliance.md)
  - this makes the build immediately available to "internal" iTunes Connect users
4. Add at least one other "Group" of "external" testers to the build
  - after review, this will make it available for all those "external" testers
  - example: "lockbox-dev" which includes our other non-iTunes Connect engineers
  - example: "Product" which includes other product and content Mozillians

## Distributing through the App Store (release)

1. Browse to iTunes Connect
2. ???
3. Profit

---

[1]: https://dashboard.buddybuild.com/apps/5a0ddb736e19370001034f85
[2]: https://developer.apple.com/testflight/testers/
[3]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270/testflight?section=iosbuilds
