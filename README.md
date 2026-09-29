# Country Flag Trivia

A Flutter quiz that shows a country flag and asks you to identify it. Every
flag in the pool is used exactly once, you get three attempts per flag, and the
run ends with a results screen once the pool is exhausted.

## Game rules

| Rule | Behaviour |
| --- | --- |
| Pool | Every country returned by the API, used as the answer **exactly once** |
| Options | 1 correct country + 3 wrong ones, shuffled, re-shuffled every round |
| Attempts | 3 per flag; a wrong option is locked out red and cannot be re-tapped |
| 1st try correct | 10 points |
| 2nd try correct | 8 points |
| 3rd try correct | 5 points |
| All 3 wrong | 0 points, the answer is revealed, the run moves on |
| Completion | When every country has been played, the results screen shows the final score, correct answers and accuracy, with a **Reset game** button that restores the full pool |

The header tracks the live score, progress (`solved / total`) and the attempts
left on the current flag, including how many points that flag is still worth.

## Data sources

Two endpoints are used, both key-free:

- **Countries** — `https://countriesnow.space/api/v0.1/countries/iso`
  (see the note below)
- **Flags** — `https://flagcdn.com/w320/{iso}.png`, keyed on the lowercase
  ISO 3166-1 alpha-2 code, cached on disk via `cached_network_image`

### Two deviations from the original brief

Both were required to make the app actually work, and both are isolated behind
a single constant so they are trivial to swap back:

1. **Country feed.** The brief pointed at `https://getpostman.com`, which is
   Postman's marketing site, not an API — it returns HTML and no country data.
   `ApiConstants.countriesUrl` therefore defaults to a working public feed that
   returns 222 countries. The parser is deliberately lenient about field names
   and envelope shapes, so pointing this at a Postman mock or any other
   provider is a one-constant change. All 222 ISO codes it returns are
   verified to resolve on FlagCDN.

2. **Flag URL.** The brief specified `https://flagcdn.com{iso}.png`, which
   returns **HTTP 404** — FlagCDN requires a size segment. The code uses
   `https://flagcdn.com/w320/{iso}.png`, which returns a 1–2 KB PNG.

If the network is unavailable, the repository falls back to a bundled snapshot
of the country list so a cold start still produces a playable game rather than
a dead end.

## Architecture

Clean-ish layering with a single direction of dependency, and the only place
each concern lives:

```
lib/
├── core/            # cross-cutting: API constants, HTTP client, errors, theme
├── data/            # models, remote + local data sources, repository impl
├── domain/          # entities, repository contract, use cases
└── presentation/    # bloc, pages, widgets
```

- **State management** — `flutter_bloc`. A single `GameBloc` owns the country
  pool, question dealing, attempt tracking and scoring; the UI is stateless
  and driven entirely by `GameState`.
- **Error handling** — data sources throw typed exceptions; the repository
  converts them into `Failure`s inside a `Result<T>` sealed class, so the
  presentation layer has no `try`/`catch` and every error is an explicit
  branch.
- **Data parsing** — `CountryModel` accepts the field aliases used across
  common country APIs (`name`/`common`/`country`, `iso2`/`cca2`/`alpha2Code`/…)
  and skips malformed entries instead of crashing.

## Running it

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter analyze
flutter test
```

Coverage includes the data sources and repository fallbacks, the full bloc
(lifecycle, non-repeating questions, per-attempt scoring, input guards, reset)
and widget tests for the quiz screen and the results screen.

## Known issues

Tracked and addressed by the follow-up pull requests:

- rounds can fall back to three answer options once the pool runs dry and the
  player has been failing flags
- a successful retry does not clear the error message from the previous failure
- options the player never guessed are painted red, as if they were mistakes
- `test/widget_test.dart` is still the Flutter counter template and does not
  compile
