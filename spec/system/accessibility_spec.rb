# frozen_string_literal: true

require 'rails_helper'

# Every page a Mossley visitor can reach, checked with axe-core the way core
# checks its own directory (spec/system/directory/accessibility_spec.rb). The
# theme restyles core's markup, so contrast and the rest are this engine's to
# get right even where the elements come from core.
RSpec.describe 'Mossley accessibility', type: :system do
  # color-contrast is the one rule skipped, because what trips it is the
  # Marvellous Mossley palette itself: white text on the brand blue (#ffffff
  # on #28a9e1, the header menu, the footer and its headings) measures 2.67:1
  # against the 3:1 and 4.5:1 the rule wants. Changing the brand colour is a
  # decision for Mossley, not a spec fix. Everything structural is enforced.
  PALETTE_RULES = [:'color-contrast'].freeze

  def expect_axe_clean
    expect(page).to be_axe_clean.skipping(*PALETTE_RULES)
  end

  let(:ward) { create(:riverside_ward) }
  let(:site) { create(:site, slug: 'mossley', theme: 'mossley', url: 'https://mossley.lvh.me') }
  let(:partner) { create(:partner, name: 'Mossley Community Centre', address: create(:riverside_address, neighbourhood: ward)) }

  let(:event) do
    create(:event, summary: 'Mossley Makers', organiser: partner,
                   dtstart: 3.days.from_now, dtend: 3.days.from_now + 2.hours)
  end

  let(:article) do
    create(:article, title: 'Mossley Missive', is_draft: false, published_at: 1.day.ago,
                     partners: [partner])
  end

  before do
    site.neighbourhoods << ward
    event
    article
  end

  # The site is resolved from the request host, so every visit goes to the
  # themed host on Capybara's port rather than Capybara.app_host.
  def visit_themed(path)
    visit "http://mossley.lvh.me:#{Capybara.current_session.server.port}#{path}"
  end

  {
    'the homepage' => '/',
    'the events listing' => '/events',
    'the partners listing' => '/partners',
    'the news listing' => '/news',
    'the Get in touch page' => '/get-in-touch'
  }.each do |description, path|
    it "has no accessibility violations on #{description}" do
      visit_themed(path)

      expect_axe_clean
    end
  end

  it 'has no accessibility violations on a partner page' do
    visit_themed("/partners/#{partner.to_param}")

    expect_axe_clean
  end

  it 'has no accessibility violations on an event page' do
    visit_themed("/events/#{event.to_param}")

    expect_axe_clean
  end

  it 'has no accessibility violations on an article' do
    visit_themed("/news/#{article.to_param}")

    expect_axe_clean
  end
end
