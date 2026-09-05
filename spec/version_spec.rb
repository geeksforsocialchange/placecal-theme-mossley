# frozen_string_literal: true

require 'English'
require 'json'
require 'spec_helper'
require_relative '../lib/mossley/version'

# A PlaceCal installation pins this engine by tag, so the released tags and
# VERSION have to stay in step. The bump lands before the tag is cut, so the
# latest tag may be one behind VERSION; a tag ahead of VERSION means a release
# went out without the bump, which would leave two different builds claiming
# the same version.
RSpec.describe 'Mossley::VERSION' do
  ENGINE_ROOT = File.expand_path('..', __dir__)

  def latest_tag
    tag = `git -C #{ENGINE_ROOT} describe --tags --abbrev=0 2>/dev/null`.strip
    return nil unless $CHILD_STATUS.success? && tag.start_with?('v')

    tag
  end

  it 'is a released-looking version number' do
    expect(Mossley::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'is at or ahead of the latest git tag' do
    tag = latest_tag
    skip 'no git tags available (shallow clone or no git)' if tag.nil?

    expect(Gem::Version.new(tag.delete_prefix('v'))).to be <= Gem::Version.new(Mossley::VERSION)
  end

  it 'matches the version in package.json' do
    package = JSON.parse(File.read(File.join(ENGINE_ROOT, 'package.json')))

    expect(package['version']).to eq(Mossley::VERSION)
  end
end
