# frozen_string_literal: true

source 'https://gem.coop'

# This Gemfile exists for gem metadata and tooling only. The specs boot the
# PlaceCal core application, which needs core's full gem set, so they run with
# BUNDLE_GEMFILE pointed at the core checkout's Gemfile. See README Development.
gemspec

group :development, :test do
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop', '1.89.0', require: false
  gem 'rubocop-graphql', '1.8.0', require: false
  gem 'rubocop-performance', '1.27.0', require: false
  gem 'rubocop-rails', '2.37.0', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end
