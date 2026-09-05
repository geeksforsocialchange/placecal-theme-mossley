# frozen_string_literal: true

# The Marvellous Mossley homepage, moved out of core (was
# Views::Sites::Mossley). Same markup and same copy; the literals core carried
# inline are now locale keys under mossley.*, and the share image ships with
# this engine rather than with core.
class Mossley::Views::Home < Views::Base
  prop :site, Site, reader: :private

  # The share image logical path, guarded below. image_url raises
  # Propshaft::MissingAssetError on a missing asset, which would 500 the
  # homepage; core's own theme.og_image degrades instead, and this keeps the
  # same promise while staying homepage-only.
  OG_IMAGE = 'mossley/og.png'

  # Core's layout appends the site name to any :title set here, so a theme
  # that wants the bare site name sets no :title at all.
  def view_template
    content_for(:image) { image_url(OG_IMAGE) } if PlaceCal::Theme.asset_resolves?(OG_IMAGE)

    render_hero
    render_mission
    render_about
    render_support
  end

  private

  def render_hero
    section do
      div(class: 'hero_image--mossley')
    end

    section(class: 'region region__title--mossley') do
      div(class: 'container-narrowish') do
        h1 { t('mossley.home.hero.heading') }
      end
    end
  end

  def render_mission
    section(class: 'region region__mission') do
      div(class: 'container-narrow') do
        p { t('mossley.home.mission.groups') }
        p { t('mossley.home.mission.projects') }
        p { render_mission_links }
        link_to t('mossley.home.mission.events_cta'), events_path, class: 'btn btn--lg btn--alt btn--mt'
      end
    end
  end

  # One sentence with two inline links, so the copy is split across the pieces
  # either side of them rather than built by interpolation.
  def render_mission_links
    plain t('mossley.home.mission.working_with')
    plain ' '
    link_to t('mossley.home.mission.partners_link'), partners_path
    plain ' '
    plain t('mossley.home.mission.and')
    plain ' '
    link_to t('mossley.home.mission.places_link'), places_path
    plain ' '
    plain t('mossley.home.mission.calendar_for', site: site.name)
  end

  def render_about
    section(class: 'region region__management') do
      div(class: 'title-strip') do
        h2(class: 'h2--alt') { t('mossley.home.about.heading') }
      end
      div(class: 'container-narrow first-ele-h3') do
        p { t('mossley.home.about.join') }
        p { t('mossley.home.about.support') }
        raw safe(site.description_html.to_s)
        Profile(user: site.site_admin) if site.site_admin.present?
      end
    end
  end

  def render_support
    section(class: 'region region__support') do
      div(class: 'container-public') do
        div(class: 'g') do
          div(class: 'gi gi__1-3') do
            HelpCard(variant: :adding_events, site: site)
          end
          div(class: 'gi gi__1-3') do
            HelpCard(places: places_to_get_online, variant: :computer_access)
          end
          div(class: 'gi gi__1-3') do
            HelpCard(variant: :getting_help)
          end
        end
      end
    end
  end

  # Core's SitesController builds a theme homepage with `new(site:)` only, so
  # the "places to get online" list the help card offers is looked up here.
  # Same query core's controller runs for its own homepage, honouring the
  # region control when one is selected.
  def places_to_get_online
    return @places_to_get_online if defined?(@places_to_get_online)

    @places_to_get_online =
      PartnersQuery.new(site: site).call(tag_slug: 'computers', partnership_id: view_context.current_region&.id)
  end
end
