# Overview
This document tries to describe the state of the test automation on Lockwise iOS

# Current status
Automated tests are running on BuddyBuild as part of each PR and when there is a new commit on master. 
There are three schemes containing the different test types.
- Lockbox scheme for unit tests
- uispecs scheme for XCUITests checking the app at User Interface level
- L10nSnapshotsTests for XCUITests in charge of generating the screenshots


## Tests part of the development process
For new PRs or new commits on master lockbox and uispecs tests are running. XCUITests are running on both iPhone (8) and iPad (Air2) simulator since they test the UI of the app, closer to what a real user would do, and there are differences that need to be checked depending on the device.


## Tests to generate screenshots
L10nSnapshots tests will be run in the future as part of the CI but is not defined yet how/how often.
While the process is added to the CI, screenshots can be generated locally. The environment is set up once the repo is cloned and built so only these steps will be needed:

1. From command line run: `fastlane snapshot`
2. Screenshots will be saved in `fastlane/screenshots/` folder

If screenshots are not saved, it may be necessary to create that folder locally.

Current locales are defined in `fastlane/Snapfile` as well as the scheme to test. This file can be modified to add/remove locales while generating the screenshots.
Once screenshots for each locale are generated, they are stored in [`drive`](https://drive.google.com/drive/folders/1dghwymAw5a8TbhhHZvA0Ag4qbgxJ1fDM?usp=sharing). This may change in the future but for now, they live there.