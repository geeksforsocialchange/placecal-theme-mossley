# placecal-theme-mossley

The Marvellous Mossley theme for [PlaceCal](https://github.com/geeksforsocialchange/PlaceCal), packaged as a PlaceCal extension (a Rails engine). It provides the theme stylesheet, the homepage, the copy, the artwork and the map style for the Mossley site, which is served by PlaceCal.

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
app/assets/builds/map-styles/      MapLibre style JSON, served by Propshaft
app/assets/images/mossley/         Backgrounds, hero artwork and the share card
config/locales/en.yml              Theme strings, namespaced under mossley.*
bin/mossley-dev-gemfile            Writes core's Gemfile.mossley-dev for dev and CI
```

There are deliberately no models, migrations, controllers or routes, and no components: the homepage is built from core's own components. Every visible string goes through `t()`.

## Installation

Add the engine to the PlaceCal installation's `Gemfile`, pinned to a tag, in the single removable extensions block described in core's `doc/extensions.md`:

```ruby
# Installation-specific extensions for placecal.org. Not part of core: a
# self-hosted PlaceCal can delete this block.
group :extensions do
  gem 'placecal-theme-transdimension',
      github: 'geeksforsocialchange/placecal-theme-transdimension',
      tag: 'v0.3.10'
  gem 'placecal-theme-mossley',
      github: 'geeksforsocialchange/placecal-theme-mossley',
      tag: 'v0.1.1'
end
```

The CSS is committed prebuilt, so core's Docker build needs no extra Node step.

### Minimum core

The host has to be a PlaceCal with the extension theme registry. Specifically, `PlaceCal::Extensions.register_theme` must exist and the theme it yields must support every setting this engine uses:

`stylesheet`, `homepage_view`, `map_style`

The engine checks this while it registers, and raises `Mossley::UnsupportedHost` naming the missing capability rather than failing with a `NoMethodError` from inside an initializer. `Mossley::Engine::REQUIRED_THEME_SETTINGS` is the list it checks.

The check is `respond_to?` and nothing more, so it catches a setting that is absent, not one whose signature changed. That drift is covered by `spec/host_contract_spec.rb`, which runs `Mossley::Engine.configure_theme` against a real `PlaceCal::Theme` and reads every setting back.

The host also has to be a PlaceCal whose Mossley site is on theme `mossley` rather than the old `custom`. Core ships the data migration that does it.

## Development

The specs boot the PlaceCal core application with this engine loaded, so they need a checkout of core and core's gem bundle. Check core out next to this repo (the default core path is `../PlaceCal`, override it with `PLACECAL_CORE_PATH`).

Core's own `Gemfile` pins this engine to a git tag, which would run the specs against the released gem rather than your working tree. So point Bundler at a Gemfile that swaps that pin for a `path:` entry. `bin/mossley-dev-gemfile` writes it into the core checkout (do not commit it there; add it to core's `.git/info/exclude`). It puts **both** PlaceCal theme engines on paths, so one boot loads two extensions, which is what `spec/requests/two_engines_spec.rb` needs. CI runs the same script and drops the Trans Dimension line, so that spec skips there.

```sh
bin/mossley-dev-gemfile /path/to/PlaceCal
```

Then run the specs against it:

```sh
cd /path/to/placecal-theme-mossley
PLACECAL_CORE_PATH=/path/to/PlaceCal \
  BUNDLE_GEMFILE=/path/to/PlaceCal/Gemfile.mossley-dev \
  RAILS_ENV=test bundle exec rspec
```

`spec/rails_helper.rb` aborts with an explanatory message if the booted engine is not this working tree, so a stale Gemfile fails loudly instead of quietly testing the installed tag.

This engine's own `Gemfile` exists for gem metadata and tooling; it cannot resolve the gems core needs to boot, which is why the invocations above point Bundler at core. RuboCop runs the same way:

```sh
BUNDLE_GEMFILE=/path/to/PlaceCal/Gemfile.mossley-dev bundle exec rubocop
```

### Releasing

Installations pin this engine by tag, so a release is a version bump followed by a tag. Bump `lib/mossley/version.rb` and `package.json` together (a spec fails if they disagree, or if the latest tag is ahead of `VERSION`), merge, then tag the merge commit `v<version>`. CI fails a tag push whose tag name does not match `VERSION`.

### Sass

This theme is Sass, not Tailwind: it is a port of the stylesheet core built with dartsass, kept as-is so the move changed nothing visible. The source is `app/scss/mossley.scss`, built by the `sass` npm package (pinned to the same dart-sass version core's `sass-embedded` uses) into `app/assets/builds/mossley/theme.css`. That build is committed and CI fails when it is stale.

```sh
yarn install
yarn build      # rebuild the committed CSS
yarn css-check  # fail if the committed CSS is stale
```

`app/scss/variables_mixins.scss` and the `variables/` and `modules/` partials under it are copies of core's, taken at the point of extraction. They are the compile inputs the theme has always had. A new theme should not copy them: it should be Tailwind plus CSS custom properties, as `doc/extensions.md` describes.

The one thing the move changed in the CSS is where the background images come from. In core the stylesheet pointed at `/images/regions/mossley/...`, files core served out of `public/`. They now ship with this engine under `app/assets/images/mossley/`, and the stylesheet refers to them by name, so Propshaft rewrites each `url()` to the fingerprinted asset path. The rest of the compiled file is byte-for-byte what core built.

### Map style

`app/assets/builds/map-styles/mossley.json` is the MapLibre style core used to serve from `public/map-styles/`. Propshaft picks it up at the same logical path, and `MapHelper#map_style_url` finds it there once core's copy is gone.
