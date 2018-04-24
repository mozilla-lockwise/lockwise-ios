# Release Instructions

Some assumptions:

- `master` is the default branch and is production-ready
- commits made to master are built and pass in [buddybuild][1]
- all builds are sent to iTunes Connect, with the same buddybuild build number

## Distributing Builds through buddybuild (branch / release)

_all commits on all branches and pull requests are automatically built_

1. Push to the GitHub branch
2. Open [buddybuild][1] from a mobile device and browse to the build
3. Alternatively, add an email address to the "Deployments" email list(s)

## Distributing Builds through TestFlight (release)

1. Browse to [TestFlight > Builds > iOS][2]
2. Find the desired build number to distribute
3. Provide [export compliance responses](export-compliance.md)
  - this makes the build immediately available to iTunes Connect testers
4. Add at least one other "Group" to the build
  - after review, this will make it available for all "external" testers
  
## Distributing through the App Store (release)

1. Browse to iTunes Connect
2. ???
3. Profit

---

[1]: https://dashboard.buddybuild.com/apps/5a0ddb736e19370001034f85
[2]: https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1314000270/testflight?section=iosbuilds
