# frozen_string_literal: true

# Boots the PlaceCal core application with this engine loaded, the way Bundler
# would load the gem in a real installation. All of it is core's knowledge, so
# core owns it; see doc/extensions.md there, and README "Development" here.
require 'spec_helper'

PLACECAL_CORE = Pathname(ENV.fetch('PLACECAL_CORE_PATH', File.expand_path('../../PlaceCal', __dir__))).expand_path
require PLACECAL_CORE.join('spec/extension_helper').to_s
PlaceCal::ExtensionSpec.boot!(engine: 'mossley', system_specs: true)
