# Release Notes

## 1.0 (Build ???????)

What's NEW? We squashed a bunch of bugs (timed lock works better now, not perfectly) and added a few improvements (indicator when a sync is happening, and preventing it from interrupting you). To recap...

This build DOES include:

- signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox
- automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data
- searching and sorting items
- showing/hiding passwords
- coping usernames and passwords to the pasteboard (which expire after 60 seconds)
- opening web addresses in your preferred web browser
- Telemetry for event tracking (no personally-identifiable information is collected).

This build DOES NOT include:

- user-friendly item titles (#193)
- links to real FAQ content (#172 and #340)
- meaningful instructions when no items are found (#44)

Some KNOWN ISSUES include:

- the autolocking timer is working inconsistently and may not automatically lock the app (#383)
- you may sign in and get a "confirmation" email, the app doesn't tell you that you need to go find that email so your list appears empty - please go find that email (#328)

Join us at [https://github.com/mozilla-lockbox/lockbox-ios/issues][1] to find any of the above items or report new issues you encounter.

## 1.0 (Build 1128)

_Date: 2018-05-14_

This build DOES include: signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox; automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data; searching and sorting items; showing/hiding passwords; coping usernames and passwords to the pasteboard (which expire after 60 seconds); opening web addresses in your preferred web browser; Telemetry for event tracking (no personally-identifiable information is collected).

This build DOES NOT include: user-friendly item titles (#193); links to real FAQ content (#172 and #340); proper visual placeholders when an initial sync is occurring (#233) or when no items are found (#44).

Some KNOWN ISSUES include: you may sign in and get a "confirmation" email, the app doesn't tell you that you need to go find that email so your list appears empty - go find that email and "Confirm" your sign ins, please (#328); the autolock timer doesn't automatically lock your app (#356); when navigating away from the list view and a sync occurs in the background the app will pop you back into the list view (#347); the search/filter keyboard is immediately dismissed after the first and second character you type (#351). Don't worry, we'll get these fixed soon!

Please also note: the app may crash on first run — just open it again and please let us know if you encounter this or anything unexpected. We believe we squashed all kinds of bugs related to first run and sign in but need your help making sure.

## 1.0 (Build 742)

_Date: 2018-04-24_

This build includes: sign in with Firefox Accounts, sign out to "lock", search and sort items, show/hide passwords, copy username and password to pasteboard (expires after 60 seconds), open web addresses in preferred web browser.

This build does NOT include: actual Sync data (test data only), Face ID nor Touch ID biometrics to unlock, onboarding instructions, FAQ content.

Please note: the only data loaded into the app is hard-coded test data (not real Sync data)

[1]: https://github.com/mozilla-lockbox/lockbox-ios/issues
