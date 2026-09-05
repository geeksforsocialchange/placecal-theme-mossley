# frozen_string_literal: true

require 'rails_helper'

# WP 5.1: the Mossley theme is an extension. Core no longer knows the site
# exists; the engine registers the theme and core renders it.
RSpec.describe 'Mossley theme', type: :request do
  let(:site) do
    create(:site, slug: 'mossley', theme: 'mossley', name: 'Marvellous Mossley',
                  tagline: 'Our town, all in one place', url: 'https://mossley.lvh.me')
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

    # Core's layout appends the site name to any content_for(:title), so a
    # theme setting the title to the site name prints it twice (#3368).
    it 'titles the page with the site name once' do
      get 'http://mossley.lvh.me/'

      expect(response.body).to include('<title>Marvellous Mossley</title>')
    end

    it 'uses the engine share image' do
      get 'http://mossley.lvh.me/'

      expect(response.body).to match(%r{property="og:image" content="[^"]*/assets/mossley/og-[0-9a-f]+\.png"})
    end

    # image_url raises Propshaft::MissingAssetError when the file is renamed or
    # dropped, so the homepage would 500 rather than fall back to core's
    # generated share card the way theme.og_image does (#3368).
    it 'falls back to core\'s share card when the engine image is missing' do
      allow(PlaceCal::Theme).to receive(:asset_resolves?).and_call_original
      allow(PlaceCal::Theme).to receive(:asset_resolves?).with('mossley/og.png').and_return(false)

      get 'http://mossley.lvh.me/'

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to match(%r{property="og:image" content="[^"]*/assets/mossley/og-})
    end
  end

  # app/scss/mossley.scss hides the hero tagline with `.hero p.allcaps`, which
  # names the element core's Components::Hero emits. Core moved that from an h4
  # to a p once already (this repo needed b51e760 to catch up), and neither
  # suite noticed. Assert the element so a second move fails loudly here rather
  # than showing a duplicated tagline on every interior page.
  describe 'interior pages' do
    it 'renders the tagline in the element the theme stylesheet hides' do
      get 'http://mossley.lvh.me/events'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<p class="allcaps">Our town, all in one place</p>')
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

  # The theme names one of core's four shipped styles rather than shipping a
  # copy of it, so there is no engine asset here to go stale against core's.
  describe 'the map style' do
    it 'resolves the name from the theme' do
      expect(PlaceCal::Extensions.fetch_theme('mossley').map_style_name).to eq('blue')
    end

    it 'ships no style JSON of its own' do
      expect(Rails.application.assets.resolver.resolve('map-styles/mossley.json')).to be_nil
    end

    it 'is the URL MapHelper hands the map' do
      Current.site = site
      Current.theme = PlaceCal::Theme.for(site)

      url = ApplicationController.new.view_context.send(:map_style_url)

      expect(url).to eq('/map-styles/blue.json')
    ensure
      Current.reset
    end
  end
end
