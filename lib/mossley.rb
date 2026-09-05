# frozen_string_literal: true

# Marvellous Mossley: a PlaceCal extension (Rails engine) that registers the
# `mossley` theme. Extensions hold views, assets and copy only: no models, no
# migrations, no business logic. See core's doc/extensions.md and #3368.
module Mossley
  # Phlex namespaces. Core owns Views and Components; an extension owns
  # <Extension>::Views and <Extension>::Components.
  module Views; end

  module Components
    extend Phlex::Kit
  end
end

# An older core has no PlaceCal::Extension, and the engine's class body would
# fail with a bare NameError instead of saying what is missing.
abort('placecal-theme-mossley needs a PlaceCal with PlaceCal::Extension; see "Minimum core" in README.md.') unless defined?(PlaceCal::Extension)

require_relative 'mossley/version'
require_relative 'mossley/engine'
