# placecal-theme-mossley

The Marvellous Mossley theme for [PlaceCal](https://github.com/geeksforsocialchange/PlaceCal), packaged as a PlaceCal extension (a Rails engine). It provides the theme stylesheet, the homepage, the copy and the artwork for the Mossley site, which is served by PlaceCal.

Extensions contain no models, no migrations and no business logic. See PlaceCal's `doc/extensions.md` for the extension contract.

This theme used to live in core, as the legacy `custom` theme resolved by site slug (`app/views/sites/mossley.rb`, `app/assets/stylesheets/themes/custom/mossley.scss`, `public/map-styles/mossley.json`). Core has no per-site special cases left: the site's `theme` column now says `mossley` and everything Mossley-shaped is in this repo.

## Layout

```
lib/mossley.rb                     Module and Phlex namespaces
lib/mossley/engine.rb              Autoload dir and theme registration
app/views/mossley/home.rb          The homepage (Mossley::Views::Home)
app/scss/mossley.scss              Sass source
app/scss/variables_mixins.scss     Core's Sass variables and mixins, copied
app/scss/variables/, modules/      The partials variables_mixins imports
app/assets/builds/mossley/         Built CSS, committed, served by Propshaft
app/assets/images/mossley/         Backgrounds, hero artwork and the share card
config/locales/en.yml              Theme strings, namespaced under mossley.*
```

There are deliberately no models, migrations, controllers or routes, and no components: the homepage is built from core's own components. Every visible string goes through `t()`.

## Installation

The engine goes in the PlaceCal installation's `Gemfile`, pinned to a tag, in the single removable extensions block. The block and the version to pin are core's, not this repo's: see [Installation and Gemfile](https://github.com/geeksforsocialchange/PlaceCal/blob/main/doc/extensions.md#installation-and-gemfile) in core's `doc/extensions.md`.

The CSS is committed prebuilt, so core's Docker build needs no extra Node step.

### Minimum core

The host has to be a PlaceCal that ships `PlaceCal::Extension`, the shared engine infrastructure this engine includes. Core requires it from `config/application.rb` before Bundler requires the extension gems; on a core too old to have it, the two-line guard in `lib/mossley.rb` aborts naming this gem rather than raising a `NameError` from the middle of a class body.

The theme that core yields also has to support every setting this engine declares in `required_settings`:

`stylesheet`, `homepage_view`, `map_style`

`PlaceCal::Extension` checks that while it registers, and raises `PlaceCal::Extension::UnsupportedHost` naming the missing setting rather than failing with a `NoMethodError` from inside an initializer.

The check is `respond_to?` and nothing more, so it catches a setting that is absent, not one whose signature changed. That drift is covered by `spec/host_contract_spec.rb`, which runs `Mossley::Engine.configure_theme` against a real `PlaceCal::Theme` and reads every setting back.

The host also has to be a PlaceCal whose Mossley site is on theme `mossley` rather than the old `custom`. Core ships the data migration that does it.

## Development

The specs boot the PlaceCal core application with this engine loaded, so they need a checkout of core and core's gem bundle. Check core out next to this repo (the default core path is `../PlaceCal`, override it with `PLACECAL_CORE_PATH`), then follow [Running an extension's suite](https://github.com/geeksforsocialchange/PlaceCal/blob/main/doc/extensions.md#running-an-extensions-suite) in core's `doc/extensions.md`. For this engine that is:

```sh
# from the core checkout
bin/extension-dev-gemfile placecal-theme-mossley=../placecal-theme-mossley

# from this checkout
PLACECAL_CORE_PATH=/path/to/PlaceCal \
  BUNDLE_GEMFILE=/path/to/PlaceCal/Gemfile.extensions-dev \
  RAILS_ENV=test bundle exec rspec
```

The generator leaves every extension it is not asked to swap at the tag core pins, so one boot still loads both theme engines, which is what `spec/requests/two_engines_spec.rb` needs. `PlaceCal::ExtensionSpec.boot!` aborts with an explanatory message if the booted engine is not this working tree, so a stale Gemfile fails loudly instead of quietly testing the installed tag.

This engine's own `Gemfile` exists for gem metadata and tooling; it cannot resolve the gems core needs to boot, which is why the invocations above point Bundler at core. RuboCop runs the same way, and reads its rules from the core checkout beside it:

```sh
BUNDLE_GEMFILE=/path/to/PlaceCal/Gemfile.extensions-dev bundle exec rubocop
```

`PLACECAL_CORE_PATH` does not reach RuboCop. `.rubocop.yml` inherits from `../PlaceCal/config/rubocop/extension.yml`, a plain relative path, so linting needs the core checkout to sit literally at `../PlaceCal` whatever the env var says. Without it RuboCop aborts with "Configuration file not found" and reports no offences.

### Releasing

The release convention is the same for every extension and lives in core: see [Releasing an extension](https://github.com/geeksforsocialchange/PlaceCal/blob/main/doc/extensions.md#releasing-an-extension) in `doc/extensions.md`. For this engine the version lives in `lib/mossley/version.rb` and `package.json`, and `spec/version_spec.rb` fails if the two disagree or if the latest tag is ahead of `VERSION`.

### Sass

This theme is Sass, not Tailwind: it is a port of the stylesheet core built with dartsass, kept as-is so the move changed nothing visible. The source is `app/scss/mossley.scss`, built by the `sass` npm package (pinned to the same dart-sass version core's `sass-embedded` uses) into `app/assets/builds/mossley/theme.css`. That build is committed and CI fails when it is stale.

```sh
yarn install
yarn build      # rebuild the committed CSS
yarn css-check  # fail if the committed CSS is stale
```

`app/scss/variables_mixins.scss` and the `variables/` and `modules/` partials under it are copies of core's, taken at the point of extraction. They are the compile inputs the theme has always had. A new theme should not copy them: it should be Tailwind plus CSS custom properties, as `doc/extensions.md` describes.

The move changed two things in the CSS. The background images: in core the stylesheet pointed at `/images/regions/mossley/...`, files core served out of `public/`. They now ship with this engine under `app/assets/images/mossley/`, and the stylesheet refers to them by name, so Propshaft rewrites each `url()` to the fingerprinted asset path. And the hero tagline selector, `.hero p.allcaps`, which followed core's heading-order fix moving that element from an h4 to a p; `spec/requests/theme_spec.rb` asserts the element so a second move fails here. The rest of the compiled file is byte-for-byte what core built.

### Map style

The theme sets `map_style 'blue'`, which is one of the four MapLibre styles core ships in `public/map-styles/`. `MapHelper#map_style_url` looks there before the asset pipeline, so this engine ships no style JSON of its own.

It used to. The `mossley.json` core served from `public/map-styles/` came over with the rest of the theme and turned out to be a byte-for-byte copy of core's `blue.json`, which would have gone stale the first time OpenFreeMap moved its sprite path or its tile host and core updated all four styles. Naming the style avoids that. An extension that genuinely needs its own styling still ships one, as `placecal-theme-transdimension` does.
