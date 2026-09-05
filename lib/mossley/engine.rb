# frozen_string_literal: true

module Mossley
  class Engine < ::Rails::Engine
    # Not isolate_namespace: an extension plugs into the host app's routes,
    # helpers and layout rather than living behind a mount point.
    #
    # PlaceCal::Extension is core's shared engine infrastructure: it pushes the
    # Zeitwerk directory for the app/views/mossley this engine ships, runs the
    # host and theme guards, and registers the theme below. See core's
    # doc/extensions.md.
    include PlaceCal::Extension

    # Every theme DSL setting this engine uses. The host has to provide all of
    # them; see "Minimum core" in the README. This theme is a stylesheet, a
    # homepage and a map style, so the list is short: the rest of the site is
    # core's chrome, exactly as it was when the theme lived in core.
    required_settings %i[stylesheet homepage_view map_style]

    # The views and styling core reads for a site on this theme. Mossley keeps
    # core's head, footer, nav and event filter: the theme is a skin plus a
    # homepage, which is all it ever was as core's legacy `custom` theme.
    theme :mossley do |theme|
      theme.stylesheet 'mossley/theme'
      theme.homepage_view 'Mossley::Views::Home'
      # Core's own blue OpenFreeMap style. The engine used to ship a copy of it
      # under app/assets/builds/map-styles/, byte for byte identical, which
      # would have gone stale the first time core updated the four styles in
      # public/map-styles/. MapHelper#map_style_url checks that directory
      # first, so naming the style is all this needs.
      theme.map_style 'blue'
    end
  end
end
