# frozen_string_literal: true

require 'rails_helper'

# The point of WP 5.1: two extension engines in one process, each registering
# its own theme, each site getting its own. Both gems are on the load path in
# Gemfile.mossley-dev; this spec is skipped when only one of them is loaded, so
# the engine's own CI (which loads only this gem) still passes.
RSpec.describe 'two theme engines in one process', type: :request do
  before do
    skip 'placecal-theme-transdimension is not loaded in this bundle' unless defined?(::Transdimension::Engine)
  end

  let!(:mossley_site) do
    create(:site, slug: 'mossley', theme: 'mossley', name: 'Marvellous Mossley',
                  url: 'https://mossley.lvh.me').tap { |s| s.neighbourhoods << create(:riverside_ward) }
  end

  let!(:transdimension_site) do
    create(:site, slug: 'transdimension', theme: 'transdimension', name: 'The Trans Dimension',
                  url: 'https://transdimension.lvh.me').tap { |s| s.neighbourhoods << create(:riverside_ward) }
  end

  it 'registers both themes alongside core\'s own' do
    expect(PlaceCal::Extensions.theme_names).to include('mossley', 'transdimension')
  end

  it 'keeps the two themes independent' do
    mossley = PlaceCal::Extensions.fetch_theme('mossley')
    transdimension = PlaceCal::Extensions.fetch_theme('transdimension')

    expect(mossley.stylesheet).to eq('mossley/theme')
    expect(transdimension.stylesheet).to eq('transdimension/theme')
    expect(mossley.map_style).to eq('mossley')
    expect(transdimension.map_style).to eq('transdimension')
  end

  it 'renders each site with its own homepage view' do
    get 'http://mossley.lvh.me/'
    expect(response.body).to include('Marvellous Mossley celebrates our town')
    expect(response.body).not_to include('transdimension/theme')

    get 'http://transdimension.lvh.me/'
    expect(response.body).to include('The Trans Dimension')
    expect(response.body).not_to include('mossley/theme')
  end

  it 'links each site to its own built stylesheet' do
    get 'http://mossley.lvh.me/'
    expect(response.body).to match(%r{href="/assets/mossley/theme-[0-9a-f]+\.css"})

    get 'http://transdimension.lvh.me/'
    expect(response.body).to match(%r{href="/assets/transdimension/theme-[0-9a-f]+\.css"})
  end

  it 'serves both engines\' map styles' do
    resolver = Rails.application.assets.resolver

    expect(resolver.resolve('map-styles/mossley.json')).to be_present
    expect(resolver.resolve('map-styles/transdimension.json')).to be_present
  end
end
