# frozen_string_literal: true

require 'rails_helper'

# WP 5.1: the Mossley theme is an extension. Core no longer knows the site
# exists; the engine registers the theme and core renders it.
RSpec.describe 'Mossley theme', type: :request do
  let(:site) do
    create(:site, slug: 'mossley', theme: 'mossley', name: 'Marvellous Mossley',
                  url: 'https://mossley.lvh.me')
  end

  before { site.neighbourhoods << create(:riverside_ward) }

  it 'registers the theme' do
    expect(PlaceCal::Extensions.theme_names).to include('mossley')
  end

  it 'autoloads the engine Phlex namespace' do
    expect(Mossley::Views::Home.superclass).to eq(Views::Base)
  end

  it 'loads the engine locale file' do
    expect(I18n.t('mossley.home.about.heading')).to eq('About Us')
  end

  it 'leaves the theme as an extension, not a core theme' do
    expect(PlaceCal::Extensions.find_theme('mossley')).not_to be_core
  end

  describe 'the homepage' do
    it 'renders the engine homepage view' do
      get 'http://mossley.lvh.me/'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Marvellous Mossley celebrates our town')
      expect(response.body).to include('region__title--mossley')
      expect(response.body).to include('hero_image--mossley')
    end

    it 'renders the About Us section and the help cards' do
      get 'http://mossley.lvh.me/'

      expect(response.body).to include('About Us')
      expect(response.body).to include('region__support')
    end

    it 'uses the engine share image' do
      get 'http://mossley.lvh.me/'

      expect(response.body).to match(%r{property="og:image" content="[^"]*/assets/mossley/og-[0-9a-f]+\.png"})
    end
  end

  describe 'the stylesheet' do
    it 'links the built theme stylesheet' do
      get 'http://mossley.lvh.me/'

      expect(response.body).to match(%r{<link rel="stylesheet" href="/assets/mossley/theme-[0-9a-f]+\.css"})
    end

    it 'serves the built theme stylesheet' do
      path = ActionController::Base.helpers.asset_path('mossley/theme.css')
      get path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/css')
    end

    it 'points the stylesheet background images at the engine assets' do
      get ActionController::Base.helpers.asset_path('mossley/theme.css')

      expect(response.body).to match(%r{url\("/assets/mossley/hero-desktop-[0-9a-f]+\.jpg"\)})
    end
  end

  describe 'the map style' do
    it 'resolves the name from the theme' do
      expect(PlaceCal::Extensions.fetch_theme('mossley').map_style_for(site)).to eq('mossley')
    end

    it 'ships the style JSON as an engine asset' do
      expect(Rails.application.assets.resolver.resolve('map-styles/mossley.json')).to be_present
    end

    it 'is the URL MapHelper hands the map' do
      Current.site = site
      Current.theme = PlaceCal::Theme.for(site)

      url = ApplicationController.new.view_context.send(:map_style_url)

      expect(url).to match(%r{/assets/map-styles/mossley-[0-9a-f]+\.json})
    ensure
      Current.reset
    end
  end
end
