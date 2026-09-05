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

require_relative 'mossley/version'
require_relative 'mossley/engine'
