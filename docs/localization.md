# Localization for Lockwise iOS

## Exporting Strings
1. Fork of [lockwiseios-l10n](http://github.com/mozilla-l10n/lockwiseios-l10n) to make PRs from
2. Clone the [ios-l10n-scripts]( https://github.com/mozilla-mobile/ios-l10n-scripts) repo so it is a sibling of [lockwise-ios](https://github.com/mozilla-lockwise/lockwise-ios).
3. `cd lockwise-ios`
4. `../ios-l10n-scripts/export-locales-lockwise.sh`
  - Note: at this time the `lockwise` script only exists at https://github.com/joeyg/ios-l10n-scripts/tree/add-lockwise-export-script
5. `git remote add <your username> git@github.com:<your username>/lockwiseios-l10n.git`
6. `git push <your username> <branch name>` The script automatically creates the branch for you. You just need to grab its name to push in this step.
7.  Create a PR of your l10n changes and submit it

## Adding Locales

## Importing Strings
