# Contributing to shiftviewer

Thank you for helping. This page covers how to report a problem, how to set
up the code, and what a pull request needs before it can be merged.

The project lives on [GitHub](https://github.com/uid09552/shiftviewer). Issues
and pull requests are both welcome there.

## Ways to help

- **Report a bug.** Open an issue with what you did, what you expected, and
  what happened instead. The platform (Android/iOS/web), Flutter version
  (`flutter --version`), and whether you're on a release or debug build help
  most. Leave out your own login details or anything identifying real staff.
- **Suggest a feature.** Describe the situation it solves before the
  solution — especially for anything that only makes sense with a specific
  backend deployment in mind. If the [backend](https://github.com/uid09552/shift)
  already exposes the data, that's a shiftviewer feature request; if it
  doesn't, it's a feature request there first.
- **Improve the documentation.** Corrections to this page or the README are
  always welcome, especially from someone who just went through setup fresh.
- **Translate.** UI text lives in `lib/l10n/app_en.arb` (the reference) and
  `lib/l10n/app_de.arb`. `flutter gen-l10n` fails the build until every key in
  `app_en.arb` has a match in every other `.arb` file, so a translation PR is
  either complete or it won't build — ask in the issue if you'd like help
  finishing a partial one. Adding a third language works the same way: add
  `lib/l10n/app_<code>.arb` with every key translated, then list the locale
  in `AppLocalizations.supportedLocales` and the language picker in
  `settings_screen.dart`.
- **Write code.** Pick an open issue, or open one first for anything larger
  than a fix, so we can agree on the approach before you invest time in it.

## Setting up

```sh
git clone https://github.com/uid09552/shiftviewer
cd shiftviewer
flutter pub get
flutter run
```

You'll need a backend to point the app at — see the README's
[Configuration](README.md#configuration) section. For UI work that doesn't
touch live data, the widget tests' mocked HTTP client (see `test/`) is often
enough; you don't need a running backend just to iterate on a screen.

## Before you open a pull request

```sh
flutter analyze
flutter test
```

Both must be clean. If you touched `.arb` files, also run `flutter gen-l10n`
and commit the regenerated `lib/l10n/app_localizations*.dart` — they're
checked in so the project builds without a codegen step, and a stale copy
will fail review even if your `.arb` edits were correct.

Also follow these conventions:

- **Every user-facing string goes through localization.** Add the key to
  `app_en.arb` first, then translate it in `app_de.arb` — never hard-code
  text in a widget.
- **API changes mirror `openapi.yaml`.** It's a snapshot of the backend's
  contract, not something this repo edits; if the backend added or changed an
  endpoint, say so in the PR description and update the snapshot alongside
  the client code that uses it, so the two stay comparable at a glance.
- **A failed request degrades, it doesn't crash the screen.** Look at how
  existing optional data (e.g. the day-analysis sheet, holidays) absorbs a
  403/404 from a tenant that doesn't have that feature switched on, and match
  that pattern for anything new that might not exist on every deployment.
- **Match the code around you.** Comments explain *why*, not *what*. Prefer
  small, focused changes over broad refactors, and don't reformat code you
  didn't otherwise touch — the tree isn't `dart format`-clean everywhere yet,
  and a formatting-only diff makes an unrelated change hard to review.
- **Widget tests mock the backend**, never call a real one. Follow the
  pattern in `test/admin_screens_test.dart` or `test/home_screen_test.dart`
  (a `MockClient` routing fixed JSON responses) for anything that talks to
  `ShiftDataController` or `AdminApi`.

## Reporting a security issue

Please don't open a public issue for a vulnerability that could put a real
deployment's data at risk. Open a [private security advisory](https://github.com/uid09552/shiftviewer/security/advisories/new)
on GitHub instead, or contact a maintainer directly.

## Pull requests

- Keep the diff focused on one change; unrelated cleanup belongs in its own
  PR.
- Describe what changed and why, not just what the commit does — the "why"
  is what a reviewer six months from now won't be able to reconstruct from
  the diff alone.
- Link the issue it closes, if there is one.
- Expect review comments; they're about the code, not you.
