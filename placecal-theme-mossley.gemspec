# frozen_string_literal: true

require_relative 'lib/mossley/version'

Gem::Specification.new do |spec|
  spec.name        = 'placecal-theme-mossley'
  spec.version     = Mossley::VERSION
  spec.authors     = ['Geeks for Social Change']
  spec.email       = ['support@placecal.org']
  spec.homepage    = 'https://github.com/geeksforsocialchange/placecal-theme-mossley'
  spec.summary     = 'The Marvellous Mossley theme for PlaceCal'
  spec.description = 'A PlaceCal extension engine providing the Marvellous Mossley theme: the homepage view, copy, artwork and prebuilt CSS. Contains no models, migrations or business logic.'
  # Licence to be confirmed by the maintainer; see LICENSE.
  spec.license = 'AGPL-3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.2'

  # `**/*` matches directories too, and `gem build` warns on every one of them.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,lib}/**/*', 'LICENSE', 'README.md'].select { |f| File.file?(f) }
  end

  # Core is the host application, never a dependency of the theme.
  spec.add_dependency 'rails', '>= 8.0'
end
