# frozen_string_literal: true

require 'rails_helper'

# The engine is only loadable by a PlaceCal that ships the extension theme DSL
# (#3368). Against an older core the registration would fail with a bare
# NoMethodError from inside an initializer; it names what is missing instead.
RSpec.describe 'host contract' do
  # A stand-in for an older PlaceCal::Theme: everything this engine uses except
  # homepage_view, which is what turns the theme from a skin into a site.
  let(:theme_without_homepage_view) do
    settings = Mossley::Engine::REQUIRED_THEME_SETTINGS - [:homepage_view]
    Class.new do
      settings.each { |setting| define_method(setting) { |*| nil } }
    end.new
  end

  describe '.verify_host!' do
    it 'accepts the registry core provides' do
      expect { Mossley::Engine.verify_host! }.not_to raise_error
    end

    it 'names the missing registry when the host has no extension support' do
      expect { Mossley::Engine.verify_host!(nil) }
        .to raise_error(Mossley::UnsupportedHost, /register_theme is not available/)
    end
  end

  describe '.verify_theme!' do
    it 'accepts the theme core provides' do
      theme = PlaceCal::Extensions.fetch_theme('mossley')

      expect { Mossley::Engine.verify_theme!(theme) }.not_to raise_error
    end

    it 'names the missing setting when the host theme is too old' do
      expect { Mossley::Engine.verify_theme!(theme_without_homepage_view) }
        .to raise_error(Mossley::UnsupportedHost, /does not support homepage_view/)
    end
  end

  # verify_theme! only asks respond_to?, so it cannot see the drift that is
  # actually likely between a tag-pinned core and this engine: a setting whose
  # signature changed. So register for real, against a throwaway
  # PlaceCal::Theme built the way core builds one, and read the settings back.
  describe '.configure_theme' do
    let(:theme) { PlaceCal::Theme.new(:mossley_contract_smoke) }

    before { Mossley::Engine.configure_theme(theme) }

    it 'sets the stylesheet, homepage and map style' do
      expect(theme.stylesheet).to eq('mossley/theme')
      expect(theme.homepage_view).to eq('Mossley::Views::Home')
      expect(theme.map_style).to eq('mossley')
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
end
