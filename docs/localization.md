# Localization for Lockwise iOS

The localization process for iOS is a bit of a trip:

1. Create and update a l10n repository that will collect all the strings for all the locales
2. Export strings from the app repository into that l10n repository
3. Expose the strings from the l10n repository to the Pontoon tool for translation
4. Import the string changes from the l10n repository back into the app repository

## (1) Bootstrap locales

1. From the [lockwiseios-l10n](http://github.com/mozilla-l10n/lockwiseios-l10n) repository
2. Copy the templates folder to the locale(s) to add or "bootstrap" (ex: `cp -R templates en-US`)
3. Run `update-xliff.py` to fix the target language in the file(s)
4. Create a PR to merge to the `master` branch, this will make it available for translating

## (2) Exporting Strings

1. Fork of [lockwiseios-l10n](http://github.com/mozilla-l10n/lockwiseios-l10n) to make PRs from
2. Clone the [ios-l10n-scripts]( https://github.com/mozilla-mobile/ios-l10n-scripts) repo so it is a sibling of [lockwise-ios](https://github.com/mozilla-lockwise/lockwise-ios).
3. `cd lockwise-ios`
4. `../ios-l10n-scripts/export-locales-lockwise.sh`
5. `git remote add <your username> git@github.com:<your username>/lockwiseios-l10n.git`
6. `git push <your username> <branch name>` The script automatically creates the branch for you. You just need to grab its name to push in this step.
7.  Create a PR of your l10n changes and submit it

## (3) Pontoon

Magic happens in Step 3. Learn more here:  
[https://mozilla-l10n.github.io/documentation/tools/pontoon/](https://mozilla-l10n.github.io/documentation/tools/pontoon/)

## (4) Importing Strings
_This assumes you have set up the lockwiseios-l10n repo as a sibling of lockwise-ios, see export above_

1. `cd lockwise-ios`
2. `../ios-l10n-scripts/import-locales-lockwise.sh`
3. Verify that new language files are created for the main app, credential provider extension, storyboards, and xibs. Note that if only there is no translation a new file won't be created.
