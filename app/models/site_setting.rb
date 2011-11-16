class SiteSetting
  def self.value(key)
    key = key.to_s
    raise "No such setting: #{key}" unless all_settings.has_key?(key)
    all_settings[key]
  end
  
  def self.all_settings
    @@settings ||= settings_from_files
  end
  
  def self.reset # for tests
    @@settings = settings_from_files
  end
  
  def self.host_for_remote_sandboxes
    host = value('host_for_remote_sandboxes').strip
    host = `hostname`.strip if host.blank?
    host
  end
  
  def self.port_for_remote_sandboxes
    port = value('port_for_remote_sandboxes').to_i
    port = 80 if port == 0
    port
  end
  
private
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
