# frozen_string_literal: true

require 'rails_helper'

describe 'Mossley i18n' do
  let(:en_locale) do
    YAML.load_file(File.expand_path('../config/locales/en.yml', __dir__))['en']
  end

  def flatten_keys(hash, prefix = '')
    hash.each_with_object([]) do |(key, value), memo|
      full_key = "#{prefix}#{key}"
      if value.is_a?(Hash)
        memo.concat(flatten_keys(value, "#{full_key}."))
      else
        memo << full_key
      end
    end
  end

  it 'parses en.yml without errors' do
    expect { en_locale }.not_to raise_error
  end

  it 'contains the mossley namespace and nothing else' do
    expect(en_locale.keys).to eq(['mossley'])
  end

  # The header of en.yml claims every key is read by app/ or lib/. Enforce it,
  # so a key orphaned by a future view edit fails here rather than sitting in
  # the file reading as live copy. Keys reached through an interpolated t()
  # call would make their call site a pattern rather than a literal; this
  # engine has none today, and the scan handles them if one arrives.
  it 'every key is read by app/ or lib/' do
    source = Pathname(__dir__).parent.glob('{app,lib}/**/*.rb').map(&:read).join("\n")
    patterns = source.scan(/mossley\.[a-z0-9_.]*(?:\#\{[^}]*\}[a-z0-9_.]*)*/).uniq.map do |ref|
      literals = ref.split(/\#\{[^}]*\}/, -1).map { |part| Regexp.escape(part) }
      /\A#{literals.join('[a-z0-9_]+')}\z/
    end

    flatten_keys(en_locale['mossley']).each do |key|
      full_key = "mossley.#{key}"
      expect(patterns).to be_any { |pattern| pattern.match?(full_key) },
                          "Key #{full_key} is in en.yml but nothing in app/ or lib/ reads it"
    end
  end

  it 'contains no nil or blank values' do
    flatten_keys(en_locale['mossley']).each do |key_path|
      value = key_path.split('.').inject(en_locale['mossley']) { |node, part| node[part] }
      expect(value).to be_present, "Key mossley.#{key_path} is blank"
    end
  end

  it 'resolves the engine keys through the booted app' do
    expect(I18n.t('mossley.home.about.heading')).to eq('About Us')
  end
end
