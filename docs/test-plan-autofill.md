# Test Plan for iOS 12 AutoFill

## Getting to "clean state" for testing

- Disconnect
- Disable "Lockbox" in AutoFill
- Turn off AutoFill entirely
- Delete app
- Install production version 1.2 (2051)
- Sign in
- Install master version 1.3 (2224+)

## Core test cases and expected results

1. **Upgrade from 1.2 to 1.3** (locked or unlocked): does not require FxA sign in, prompts for biometrics to unlock otherwise straight to entry list

2. **Enable AutoFill** (locked app): does prompt for biometrics, show spinner screen

3. **Enable AutoFill** (unlocked app): does not prompt for biometrics, show spinner screen

4. **Enable AutoFill then cancel biometrics**: does prompt then take back to settings

5. **Open App** (manually locked app): does prompt for biometrics

6. **Open App** (timer locked): does prompt

7. **Open App** (unlocked during autofill enabling): does prompt (again)

8. **Safari QuickType tap-to-fill** (unlocked app): does (system) prompt for biometrics

9. **Safari QuickType tap-to-fill** (locked app): does (system) prompt for biometrics

10. **QTB tap into entry list** (unlocked): does not prompt for biometrics

11. **QTB tap into entry list** (locked): does prompt for biometrics

12. **Cancel QTB tap-to-fill** (locked): does prompt for biometrics then go back to app/website
