# An abstract base for classes representing extra fields on a record.
#
# See UserField for an example.
module ExtraField
  extend ActiveSupport::Concern
  included do
    def self.extra_field_kind
      self.name.underscore.gsub(/_field$/, '').to_sym
    end

    def self.all
      @all ||= ExtraField.by_kind(self.extra_field_kind)
    end

    def self.groups
      self.all.map(&:group).uniq
    end

    def self.by_group(group)
      all.select {|field| field.group == group}
    end
  end

  def initialize(options = {})
    @options = default_options.merge(options)
    raise 'Name missing' unless @options[:name]
    @value_class = Object.const_get(self.class.name + 'Value')
  end

  def options
    @options.clone
  end

  def name
    @options[:name]
  end

  def group
    @options[:group]
  end

  def field_type
    @options[:field_type].to_sym
  end

  def label
    @options[:label] || @options[:name]
  end

  def should_save?
    !@options[:hidden] && !@options[:disabled] && @options[:field_type] != :html
  end

  attr_reader :value_class

  def values
    value_class.where(kind: kind)
  end

  def kind
    self.class.extra_field_kind
  end

  def default_options
    {
      hidden: false,
      disabled: false,
      field_type: :text
    }
  end

  def self.by_kind(kind)
    if !@fields
      kinds = config_files.map {|file| File.basename(file, '_fields.rb')}
      @fields = Hash[kinds.zip(config_files).map {|k, f| [k.to_sym, load_fields(k, f)] }]
    end
    @fields[kind.to_sym] || []
  end

private
  def self.config_files
    Dir.glob("#{::Rails.root}/config/extra_fields/*_fields.rb")
  end

  def self.load_fields(kind, config_file_path)
    return [] unless File.exist?(config_file_path)

    kind = kind.to_s

    require "#{kind}_field"
    cls_name = "#{kind.camelize}Field"

    cls = Object.const_get(cls_name)
    raise "Field class not found: #{cls}" if cls == nil

    dsl = Object.new
    dsl.instance_variable_set('@cls', cls)
    dsl.instance_variable_set('@fields', [])
    dsl.instance_variable_set('@html_count', 0)

    class << dsl
      def group(group_name, &block)
        raise "Don't nest groups" if @group
        @group = group_name
        begin
          block.call
        ensure
          @group = nil
        end
      end

      def field(options)
        @fields << @cls.new({group: @group}.merge(options))
      end

      def html(text, options = {})
        @html_count += 1
        @fields << @cls.new({
          name: "html#{@html_count}",
          group: @group,
          field_type: :html,
          label: text
        }.merge(options))
      end
    end

    dsl.instance_eval(File.read(config_file_path))
    dsl.instance_variable_get('@fields')
  end
end
