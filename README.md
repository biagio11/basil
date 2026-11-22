# Basil

A number base converter with a calculator, lessons and timed exercises.
Made with Flutter, runs on the web and on Android, in Italian and English.

Try it at https://basil-bits.netlify.app

## What it does

- **Convert** between any two bases from 2 to 36. Pick the bases with the two wheels
  (scroll, drag, arrow keys or tap the label for a grid). Quick mode shows the number in
  every common base, explain mode shows the steps. Negative numbers, fractions and
  repeating digits like `0.0(0011)` work too.
- **Calc** does addition, subtraction, multiplication and division in any base and shows
  the working in columns.
- **Learn** has three short lessons with quizzes, a class mode and a cheat sheet.
- **Train** has timed challenges with personal bests and untimed practice with hints and
  solutions.

Basil has no accounts, no analytics and no cookies. Settings and records stay on the
device. Fonts and the Flutter engine are served from the same site.

## Run it

```bash
flutter pub get
flutter test
flutter run -d chrome
```

## Build for the web

```bash
dart run tool/gen_legal.dart
flutter build web --release --csp --no-web-resources-cdn --no-source-maps --no-wasm-dry-run
node tool/serve.mjs
```

`tool/serve.mjs` serves `build/web` on port 8080 with the same headers used in production
(`web/_headers`). Deploy `build/web` to any static host. With Netlify the included
`netlify.toml` builds it for you.

## Build for Android

```bash
flutter build apk --release
```

Icons come from the pixel leaf in `tool/make_icons.py` (needs Pillow).

## Contributing

Found a bug or have an idea? Open an issue at https://github.com/biagio11/basil/issues

## License

MIT, see `LICENSE`. The fonts in `assets/fonts` are under the SIL Open Font License 1.1.
