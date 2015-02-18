# Reads yaml files such that settings in child dirs are
# merged into settings from parent dirs.
# Usage:
# RecursiveYamlReader.new.read_settings(
#   :root_dir => '/foo',
#   :target_dir => '/foo/bar/baz',
#   :file_name => 'metadata.yml',
#   :defaults => {'foo' => 'bar'}  # (optional)
#   :file_preprocessor => proc_that_transforms_hash  # (optional)
# )
#
class RecursiveYamlReader
  def read_settings(options)
    @opts = options
    require_option(:root_dir)
    require_option(:target_dir)
    require_option(:file_name)

    fail ':target_dir must start with :root_dir' unless @opts[:target_dir].start_with?(@opts[:root_dir])

    root_dir = @opts[:root_dir]
    target_dir = @opts[:target_dir]
    file_name = @opts[:file_name]
    preprocessor = @opts[:file_preprocessor] || proc {}

    subdirs = target_dir.gsub(/^#{@opts[:root_dir]}\//, '').split('/')

    @result = @opts[:defaults] || {}
    merge_file("#{root_dir}/#{file_name}", &preprocessor)
    subdirs.each_index do |i|
      rel_path = "#{subdirs[0..i].join('/')}/#{file_name}"
      begin
        merge_file("#{root_dir}/#{rel_path}", &preprocessor)
      rescue
        raise "error while reading #{rel_path}: #{$ERROR_INFO}"
      end
    end

    @result
  end

  private

  def require_option(name)
    fail "option :#{name} is required" if @opts[name].nil?
  end

  def merge_file(path, &preprocessor)
    if FileTest.exists? path
      file_data = YAML.load_file(path)
      if file_data
        file_data = preprocessor.call(file_data)
        @result = @result.deep_merge(file_data)
      end
    end
  end
end
