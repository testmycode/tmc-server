class SiteSetting
  def self.value(key)
    key = key.to_s
    raise "No such setting: #{key}" unless settings_hash.has_key?(key)
    settings_hash[key]
  end
  
private
  def self.settings_hash
    @@settings_hash ||= settings_from_files
  end
  
  def self.settings_from_files
    result = {}
    settings_files.each do |path|
      if File.exist?(path)
        data = YAML.load_file(path)
        raise "Invalid configuration file #{path}" unless data.is_a? Hash
        result = result.merge(data)
      end
    end
    result
  end
  
  def self.settings_files
    config_dir = "#{Rails::root}/config"
    ["#{config_dir}/site.defaults.yml", "#{config_dir}/site.yml"]
  end
end
