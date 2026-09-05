# frozen_string_literal: true

module Mossley
  # Raised when the host PlaceCal is too old to serve this theme.
  class UnsupportedHost < StandardError; end

  class Engine < ::Rails::Engine
    # Not isolate_namespace: an extension plugs into the host app's routes,
    # helpers and layout rather than living behind a mount point.

    # Rails does not autoload app/views, so the engine pushes its own directory
    # with an explicit namespace. Core does the same for Views in
    # config/initializers/phlex.rb. There is no app/components here: the
    # homepage is built entirely from core's components.
    initializer 'mossley.phlex_namespaces', before: :set_autoload_paths do
      Rails.autoloaders.main.push_dir(
        root.join('app/views/mossley'),
        namespace: Mossley::Views
      )
    end

    # Every theme DSL setting this engine uses. The host has to provide all of
    # them; see "Minimum core" in the README. This theme is a stylesheet, a
    # homepage and a map style, so the list is short: the rest of the site is
    # core's chrome, exactly as it was when the theme lived in core.
    REQUIRED_THEME_SETTINGS = %i[stylesheet homepage_view map_style].freeze

    # An older core has no extension registry, or a registry whose Theme is
    # missing settings added later. Either way the failure would otherwise be a
    # bare NoMethodError raised from inside an initializer, which says nothing
    # about what the installation needs. Name the missing capability instead.
    def self.verify_host!(registry = host_registry)
      return if registry.respond_to?(:register_theme)

      raise UnsupportedHost,
            'PlaceCal::Extensions.register_theme is not available: this theme needs a PlaceCal ' \
            'with the extension theme registry (see "Minimum core" in the engine README).'
    end

    def self.verify_theme!(theme)
      missing = REQUIRED_THEME_SETTINGS.reject { |setting| theme.respond_to?(setting) }
      return if missing.empty?

      raise UnsupportedHost,
            "PlaceCal::Theme does not support #{missing.join(', ')}: this theme needs a newer " \
            'PlaceCal (see "Minimum core" in the engine README).'
    end

    def self.host_registry
      defined?(::PlaceCal::Extensions) ? ::PlaceCal::Extensions : nil
    end

    # Everything this engine says to a PlaceCal::Theme, in one callable place so
    # spec/host_contract_spec.rb can run it against a throwaway real Theme. A
    # changed signature in core then fails there rather than from inside an
    # initializer on the next boot.
    def self.configure_theme(theme)
      verify_theme!(theme)
      register_layout(theme)
    end

    # The views and styling core reads for a site on this theme. Mossley keeps
    # core's head, footer, nav and event filter: the theme is a skin plus a
    # homepage, which is all it ever was as core's legacy `custom` theme.
    def self.register_layout(theme)
      theme.stylesheet 'mossley/theme'
      theme.homepage_view 'Mossley::Views::Home'
      # Blue OpenFreeMap style shipped with the engine, at
      # app/assets/builds/map-styles/mossley.json.
      theme.map_style 'mossley'
    end

    # Theme registration. Runs before core's config/initializers, which is why
    # core requires the registry from config/application.rb.
    initializer 'mossley.register_theme' do
      Engine.verify_host!

      PlaceCal::Extensions.register_theme(:mossley) do |theme|
        Engine.configure_theme(theme)
      end
    end
  end
end
