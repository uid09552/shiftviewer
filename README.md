# shiftviewer

**A mobile and web client for [Shift Planner](https://github.com/uid09552/shift),**
an open-source shift-planning service for hospital wards. shiftviewer is the
calendar staff actually carry around: it shows your own roster, lets you place
shift wishes, and gives planners and admins the same management tools as the
web app, built as a single Flutter codebase for Android, iOS, and the web.

[Features](#features) ·
[Getting started](#getting-started) ·
[Configuration](#configuration) ·
[Testing](#testing) ·
[Contributing](CONTRIBUTING.md) ·
[License](#license)

---

## Why a separate client

Shift Planner already ships a web app for planners. shiftviewer exists for
everyone else checking a roster from their phone: a native-feeling calendar,
offline-friendly settings, and a login flow that survives being backgrounded
for days between shifts. It talks to the same [REST API](openapi.yaml) the web
app uses, so anything the backend can do, this app can eventually surface —
nothing here is a separate source of truth.

## Features

**For everyone**
- Month, week, and day calendar views of your own shifts, with a one-tap
  switch to see who else is on.
- Public holidays marked on the calendar (a holiday runs on Sunday times and
  counts as a weekend day for planning).
- Place, withdraw, and browse shift wishes inside the tenant's open window,
  including a bulk "paint across days" picker.
- Per-day staffing, hours, and headcount insights.
- Export a shift to a calendar app (`.ics`), or hand off to Google Calendar.
- OIDC/PKCE sign-in (Keycloak), with silent token refresh so a session
  outlives the access token's lifetime.
- English and German, switchable in-app without a restart.

**For planners and admins** (role-gated, mirrors the backend's own checks)
- Roster editing, rotation patterns (apply/preview/clear), and the constraint
  solver's optimizer runs and proposed plans.
- Fairness, audit log, and per-employee personal limits (max nights/weekends
  per month, preferred days off).
- Shifts, workstations, capabilities, and planner-settings configuration.
- User management and the shift-wish window, including its recurring
  auto-open/close schedule.

## Getting started

### Prerequisites
- [Flutter](https://docs.flutter.dev/get-started/install) (see `environment.sdk`
  in `pubspec.yaml` for the minimum Dart version this targets).
- A running [Shift Planner](https://github.com/uid09552/shift) backend (or
  your own compatible deployment) to point the app at — see
  [Configuration](#configuration).
- For Android/iOS builds: the usual platform SDKs (Android Studio / Xcode).

### Run it

```sh
flutter pub get
flutter run
```

On first launch, open **Settings** and fill in your backend's API base URL
and OIDC issuer (or ask your administrator for the values your deployment
uses). The app doesn't do anything useful until it can reach a server.

### Generating localizations

`lib/l10n/app_localizations*.dart` is generated from the `.arb` files under
`lib/l10n/` but checked into the repo, so a plain `flutter pub get` is enough
to build. After changing an `.arb` file, regenerate with:

```sh
flutter gen-l10n
```

## Configuration

Everything the app needs is entered in **Settings** and persisted locally
(via `path_provider`) rather than compiled in:

| Setting | Purpose |
|---|---|
| API base URL | The backend's REST API, e.g. `https://your-host/api/v1`. |
| OIDC issuer / client ID / redirect URI | Keycloak (or another OIDC provider) realm this app signs in against. |
| Username / password or bearer token | Manual auth, for a deployment without OIDC set up. |
| Employee ID | Optional; scopes the calendar to one employee without needing to pick them each time. |
| Language | English or German, or "follow the device". |

The project ships with defaults pointing at the maintainers' own deployment,
which is convenient for development but **not a public demo server** — point
Settings at your own backend before relying on this app for anything.

## Testing

```sh
flutter analyze
flutter test
```

Both are expected to be clean on `main`; see [CONTRIBUTING.md](CONTRIBUTING.md)
for what's expected before a pull request.

## Project layout

```
lib/
  models/      Data classes mirroring the backend's REST schemas (see openapi.yaml)
  services/    API client, auth (OIDC/PKCE), local settings, the data controller
  screens/     Top-level screens; screens/admin/ holds the planner/admin area
  widgets/     Calendar views and the reusable pieces screens are built from
  l10n/        English/German translations (app_en.arb / app_de.arb)
test/          Widget and unit tests, run against a mocked HTTP client
openapi.yaml   A snapshot of the backend API surface this app was built against
```

## License

shiftviewer is licensed under the [Apache License, Version 2.0](LICENSE).
See [NOTICE](NOTICE) for attribution.
