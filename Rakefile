# frozen_string_literal: true

# There is deliberately no spec task here. The specs boot core, so they need
# core's gem bundle; this engine's own Gemfile cannot resolve it. See
# "Development" in the README for the invocation that works.
task :default do
  abort <<~MESSAGE
    This engine's Gemfile cannot boot PlaceCal core, so `rake spec` cannot work.
    Run the specs against core's bundle instead:

      PLACECAL_CORE_PATH=/path/to/PlaceCal \\
        BUNDLE_GEMFILE=/path/to/PlaceCal/Gemfile.extensions-dev \\
        RAILS_ENV=test bundle exec rspec

    See "Development" in README.md.
  MESSAGE
end
