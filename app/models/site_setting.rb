# typed: strict
# frozen_string_literal: true

# Represents the contents of `config/site.yml`.
class SiteSetting
  extend T::Sig
  @settings = T.let(nil, T.nilable(T::Hash[String, T.untyped]))

  # Values come from YAML.
  sig { params(key: T.any(String, Symbol)).returns(T.untyped) }
  def self.value(key)
    key = key.to_s
    raise "No such setting: #{key}" unless all_settings.key?(key)
    all_settings[key]
  end

  sig { returns(T::Hash[String, T.untyped]) }
  def self.all_settings
    @settings ||= settings_from_files(settings_files)
  end

  sig { void }
  def self.use_distribution_defaults! # for tests
    @settings = settings_from_files(settings_files.select { |f| f.end_with?('site.defaults.yml') })
  end

  private
    sig { params(files: T::Array[String]).returns(T::Hash[String, T.untyped]) }
    def self.settings_from_files(files)
      result = T.let({}, T::Hash[String, T.untyped])
      files.each do |path|
        next unless File.exist?(path)
        template = ERB.new File.new(path).read
        data = YAML.safe_load template.result(binding)
        raise "Invalid configuration file #{path}" unless data.is_a? Hash
        result = result.deep_merge(data)
      end
      result
    end

    sig { returns(T::Array[String]) }
    def self.settings_files
      config_dir = "#{Rails.root}/config"
      ["#{config_dir}/site.defaults.yml", "#{config_dir}/site.yml"]
    end
end
