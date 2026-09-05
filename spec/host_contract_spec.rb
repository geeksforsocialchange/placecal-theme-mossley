# frozen_string_literal: true

require 'rails_helper'

# The host guards themselves are core's (PlaceCal::Extension) and core tests
# them. What is this engine's own is what it says to a PlaceCal::Theme, and
# `respond_to?` cannot see the drift that is actually likely between a
# tag-pinned core and this engine: a setting whose signature changed. So
# register for real, against a throwaway PlaceCal::Theme built the way core
# builds one, and read the settings back.
RSpec.describe 'host contract' do
  let(:theme) { PlaceCal::Theme.new(:mossley_contract_smoke) }

  before { Mossley::Engine.configure_theme(theme) }

  it 'sets the stylesheet, homepage and map style' do
    expect(theme.stylesheet).to eq('mossley/theme')
    expect(theme.homepage_view).to eq('Mossley::Views::Home')
    expect(theme.map_style).to eq('blue')
  end

  it 'leaves core in charge of everything else' do
    expect(theme.head).to be_nil
    expect(theme.footer).to be_nil
    expect(theme.icons).to be_empty
    expect(theme.pages).to be_empty
    expect(theme.nav_join?).to be(true)
    expect(theme.event_filter_style).to eq(:date_picker)
  end
end
