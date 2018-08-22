# Release Notes

## 1.2 (Build 1939)

_Date: 2018-08-22_

It's been a month since our launch and we've been working hard to replace the old way of logging in with Firefox Accounts and fixing some bugs. For new users, they'll encounter a smoother and clearer experience. For existing users with the app already installed, you'll just need to sign in once again.

Here's the full list of changes:

- Introduced the OAuth login flow to replace the "old" way of signing in
- Added a "migration path" so users with the app sign back in and store data properly
- The app clears your local storage and cache when you disconnect your account
- You can now "pull to refresh" to force a sync when looking at an empty list
- We fixed some alignment bugs for iPhone SEs running iOS 10
- The autolock feature has been hardened as to when and how it locks the app
- The app no longer dynamically adjusts the navigation bar sizes so it can be usable

Thanks to all our open source contributors that helped make this release possible.

## 1.1.1 (Build 1717)

_Date: 2018-07-26_

It's been two weeks since our initial public launch, and one week since we opened up to all countries. Thanks to everyone's feedback we have some minor changes and bug fixes for you in this update.

We made some changes to autolocking and want your help testing it! Please let us know if you find anything unexpected.

We also added Klar as a browser option instead of Focus, when available. Can all you German users with Klar installed please make sure it works OK?

Here's the full list of changes:

- The autolock timer pauses when on a webpage so it doesn't lock when submitting feedback or reading FAQs
- Updated the app icon to an improved version
- You can pick Klar as your preferred browser (instead of Focus) if its available on your device
- We added the app version to the settings screen and feedback survey so we can know what you're running
- Fixed a visual bug on the "Preferred Browser" table
- Added ability to "Lock Now" for users without a device passcode set
- Added more autolock timer options: 15 and 30 minutes
- Fixed a Firefox Account bug related to server configuration
- Fixed it so you return to the "Confirm Your Email" state and screen even if your app fully quits instead of starting everything over

Please note: we intentionally skipped from version 1.0 all the way to 1.1.1 for various reasons.

## 1.1.1 (Build 1663)

_Date: 2018-07-18_

We made some changes to autolocking and want your help testing it! Please let us know if you find anything unexpected.

We also added Klar as a browser option instead of Focus, when available. Can all you German users with Klar installed please make sure it works OK?

We also show the app version number in the settings screen and add it the feedback survey so folks can easily tell us which version of the app they're using.

Here's the full list of changes:

- Added more autolock timer options: 15 and 30 minutes
- The autolock timer now also pauses when viewing a webpage so it doesn't lock when submitting feedback or reading FAQs
- You can pick Klar as your preferred browser (instead of Focus) if its available on your device
- Updated the app icon to an improved version

## 1.1 (Build 1552)

_Date: 2018-06-29_

**This version was submitted to Apple.**

EASY ACCESS

- Firefox Lockbox makes it easy to access the passwords you already saved in Firefox across all your devices.
- Get your passwords on your mobile device with one simple app
- Auto import the passwords you already saved in the browser
- One touch to copy your username and password to get into apps and websites
- Open any website from the app to get into your accounts quickly

PERSONAL TO YOU

- Personalized features to keep your accounts safe and personal to just you, without added hurdles.
- Your personal Firefox Account gets you access to all your browser saved logins
- Use your face or touch to unlock the app (safe to just you)
- Keep your passwords safe with an automatic timer which locks the app
- Set the browser you want to open your website URLs

TRUSTED

- Firefox Lockbox is created by Mozilla the independent, non-profit who advocates for Internet privacy and protection for you and everyone.
- Mozilla believes that individuals’ security and privacy on the Internet are fundamental and must not be treated as optional.

## 1.1 (Build 1552)

_Date: 2018-06-28_

What's NEW? We fixed a few bugs around when the app automatically locks. Please test this out and continue using it before we submit to Apple.

## 1.1 (Build 1539)

_Date: 2018-07-27_

In addition to the "no entries after upgrade" bug fix, we are putting finishing touches together before we submit to Apple for public release...

What's NEW? Dynamic text size support, a "no entries found" state when no filter results, and Welcome screen layout fixes for iPhone SE.

## 1.1 (Build 1490)

_Date: 2018-06-21_

**Did you upgrade last week and see an empty list? Sorry! We fixed that...**

The last version was approved for the App Store! So we fixed some bugs and did a little more. We will submit another version for the public release shortly so please keep testing and help us make sure this is still stable.

What's NEW? Improved accessibility, better indicators and buttons, list sorting bug fixes, and a new "welcome" screen on first run.

## 1.1 (Build 1473)

_Date: 2018-05-31_

The last version was approved for the App Store! So we fixed some bugs and did a little more. We will submit another version for the public release shortly so please keep testing and help us make sure this is still stable.

What's NEW? Improved accessibility, better indicators and buttons, list sorting bug fixes, and a new "welcome" screen on first run.

## 1.0 (Build 1387)

**This version will be submitted to the App Store!**

What's NEW? Fixes to unlocking mechanisms, all links are linked up, and improved accessibility.

Features and functionality include:

- signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox
- automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data
- searching and sorting items
- pull to manually refresh your list of items
- user-friendly item titles to help with readability
- showing/hiding passwords
- copying usernames and passwords to the pasteboard (which expire after 60 seconds)
- opening web addresses in your preferred web browser
- meaningful instructions when you need to confirm your sign in, or if you have no items
- Telemetry for event tracking (no personally-identifiable information is collected)

## 1.0 (Build 1343)

_Date: 2018-05-25_

What's NEW? We added pull-to-refresh in the list view, a state that tells you if we're waiting on you to click a confirmation link in your email, and slightly better "pretty" title logic.

This build DOES include:

- signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox
- automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data
- searching and sorting items
- pull to manually refresh your list of items
- user-friendly item titles to help with readability
- showing/hiding passwords
- copying usernames and passwords to the pasteboard (which expire after 60 seconds)
- opening web addresses in your preferred web browser
- meaningful instructions when you need to confirm your sign in, or if you have no items
- Telemetry for event tracking (no personally-identifiable information is collected)

This build DOES NOT include:

- the remaining links to final FAQ content and instructions (#172)
- creating, updating or deleting entries (that's intentional)

Join us at [https://github.com/mozilla-lockbox/lockbox-ios/issues][1] to find any of the above items or report new issues you encounter.

## 1.0 (Build 1280)

_Date: 2018-05-23_

What's NEW? We polished the interface (colors!), squashed some bugs (lock timer!), and improved the experience for those users (unsafely!) using a device without a passcode. If your app appears empty, there is one good reason and we're working on it but check your email for a confirmation link.

This build DOES include:

- signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox
- automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data
- searching and sorting items
- user-friendly item titles to help with readability
- showing/hiding passwords
- copying usernames and passwords to the pasteboard (which expire after 60 seconds)
- opening web addresses in your preferred web browser
- meaningful instructions when you have no items found
- Telemetry for event tracking (no personally-identifiable information is collected)

This build DOES NOT include:

- an alert when we're stuck waiting on you to confirm your Firefox Accounts sign in (#417)
- a few more links to real FAQ content and instructions (#172)
- creating, updating or deleting entries (that's intentional)

Join us at [https://github.com/mozilla-lockbox/lockbox-ios/issues][1] to find any of the above items or report new issues you encounter.

## 1.0 (Build 1189)

_Date: 2018-05-18_

What's NEW? We squashed a bunch of bugs (timed locking works much better now) and added a few improvements (user-friendly titles and a sync indicator that doesn't interrupt you). To recap...

This build DOES include:

- signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox
- automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data
- searching and sorting items
- user-friendly item titles to help with readability
- showing/hiding passwords
- copying usernames and passwords to the pasteboard (which expire after 60 seconds)
- opening web addresses in your preferred web browser
- Telemetry for event tracking (no personally-identifiable information is collected).

This build DOES NOT include:

- links to real FAQ content (#172 and #340)
- meaningful instructions when no items are found (#44)

Some KNOWN ISSUES include:

- you may sign in and receive a "confirmation" email but the app wont tell you that you need to go find that email, thus your list appears empty - please go find that email (#328)
- if you delete the app and re-install it, your app may crash once (#374)
- the autolocking timer was working inconsistently and may not have automatically locked the app, please keep testing this!

Join us at [https://github.com/mozilla-lockbox/lockbox-ios/issues][1] to find any of the above items or report new issues you encounter.

## 1.0 (Build 1128)

_Date: 2018-05-14_

This build DOES include: signing in with Firefox Accounts to see your real "Saved Logins" data from Firefox; automatic locking with biometrics (Touch ID / Face ID) to prevent access to your data; searching and sorting items; showing/hiding passwords; copying usernames and passwords to the pasteboard (which expire after 60 seconds); opening web addresses in your preferred web browser; Telemetry for event tracking (no personally-identifiable information is collected).

This build DOES NOT include: user-friendly item titles (#193); links to real FAQ content (#172 and #340); proper visual placeholders when an initial sync is occurring (#233) or when no items are found (#44).

Some KNOWN ISSUES include: you may sign in and get a "confirmation" email, the app doesn't tell you that you need to go find that email so your list appears empty - go find that email and "Confirm" your sign ins, please (#328); the autolock timer doesn't automatically lock your app (#356); when navigating away from the list view and a sync occurs in the background the app will pop you back into the list view (#347); the search/filter keyboard is immediately dismissed after the first and second character you type (#351). Don't worry, we'll get these fixed soon!

Please also note: the app may crash on first run — just open it again and please let us know if you encounter this or anything unexpected. We believe we squashed all kinds of bugs related to first run and sign in but need your help making sure.

## 1.0 (Build 742)

_Date: 2018-04-24_

This build includes: sign in with Firefox Accounts, sign out to "lock", search and sort items, show/hide passwords, copy username and password to pasteboard (expires after 60 seconds), open web addresses in preferred web browser.

This build does NOT include: actual Sync data (test data only), Face ID nor Touch ID biometrics to unlock, onboarding instructions, FAQ content.

Please note: the only data loaded into the app is hard-coded test data (not real Sync data)

[1]: https://github.com/mozilla-lockbox/lockbox-ios/issues
