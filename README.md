# Straddle

Straddle is a private, local-only iPhone poker session and profit tracker.

## Features

- Cash-game and tournament session tracking
- Fast entry for date, game, stakes, venue, buy-in, cash-out, and duration
- Cumulative profit chart and all-time dashboard
- Hourly rate, total hours, session count, win rate, average win/loss, and best/worst sessions
- Cash-versus-tournament results and tournament ROI
- Venue and game performance breakdowns
- Searchable, editable session history
- Codable JSON persistence stored only in the app's Application Support container
- Premium near-black interface with restrained electric-purple and cyan accents

## Build

The project is generated with XcodeGen:

```bash
xcodegen generate
xcodebuild -project Straddle.xcodeproj -scheme Straddle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Deployment target: iOS 17.0. No account, network connection, analytics SDK, or cloud service is used by the app.
