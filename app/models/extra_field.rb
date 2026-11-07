# typed: strict
# frozen_string_literal: true

# An abstract base for classes representing extra fields on a record.
#
# See UserField for an example.
module ExtraField
  extend T::Sig
  extend ActiveSupport::Concern
  extend T::Helpers
  requires_ancestor { UserField }

  module ClassMethods
    extend T::Sig
    extend T::Helpers
    requires_ancestor { T.class_of(UserField) }

    sig { returns(Symbol) }
    def extra_field_kind
      T.must(name).underscore.gsub(/_field$/, '').to_sym
    end

    sig { returns(T::Array[UserField]) }
    def all
      @all ||= T.let(ExtraField.by_kind(extra_field_kind), T.nilable(T::Array[UserField]))
    end

    sig { returns(T::Array[T.nilable(String)]) }
    def groups
      all.map(&:group).uniq
    end

    sig { params(group: T.nilable(String)).returns(T::Array[UserField]) }
    def by_group(group)
      all.select { |field| field.group == group }
    end
  end
  mixes_in_class_methods(ClassMethods)

  # Option values come from the Ruby DSL in config/extra_fields.
  sig { params(options: T::Hash[Symbol, T.untyped]).void }
  def initialize(options = {})
    @options = T.let(default_options.merge(options), T::Hash[Symbol, T.untyped])
    raise 'Name missing' unless @options[:name]
    @value_class = T.let(UserFieldValue, T.class_of(UserFieldValue))
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def options
    @options.clone
  end

  sig { returns(String) }
  def name
    @options[:name]
  end

  sig { returns(T.nilable(String)) }
  def group
    @options[:group]
  end

  sig { returns(Symbol) }
  def field_type
    @options[:field_type].to_sym
  end

  sig { returns(String) }
  def label
    @options[:label] || @options[:name]
  end

  sig { returns(T::Boolean) }
  def should_save?
    !@options[:hidden] && !@options[:disabled] && @options[:field_type] != :html
  end

  sig { returns(T.class_of(UserFieldValue)) }
  attr_reader :value_class

  sig { returns(ActiveRecord::Relation) }
  def values
    value_class.where(kind: kind)
  end

  sig { returns(Symbol) }
  def kind
    T.cast(self.class, T.class_of(UserField)).extra_field_kind
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def default_options
    {
      hidden: false,
      disabled: false,
      field_type: :text
    }
  end

  @fields = T.let(nil, T.nilable(T::Hash[Symbol, T::Array[UserField]]))

  sig { params(kind: T.any(String, Symbol)).returns(T::Array[UserField]) }
  def self.by_kind(kind)
    fields = @fields ||= config_files.to_h do |file|
      file_kind = File.basename(file, '_fields.rb')
      [file_kind.to_sym, load_fields(file_kind, file)]
    end
    fields[kind.to_sym] || []
  end

  class ConfigDsl
    extend T::Sig
    sig { returns(T::Array[UserField]) }
    attr_reader :fields

    sig { params(field_class: T.class_of(UserField)).void }
    def initialize(field_class)
      @field_class = field_class
      @fields = T.let([], T::Array[UserField])
      @html_count = T.let(0, Integer)
      @group = T.let(nil, T.nilable(String))
    end

    sig { params(group_name: String, block: T.proc.void).void }
    def group(group_name, &block)
      raise "Don't nest groups" if @group
      @group = group_name
      begin
        yield
      ensure
        @group = nil
      end
    end

    sig { params(options: T::Hash[Symbol, T.untyped]).void }
    def field(options)
      @fields << @field_class.new({ group: @group }.merge(options))
    end

    sig { params(text: String, options: T::Hash[Symbol, T.untyped]).void }
    def html(text, options = {})
      @html_count += 1
      @fields << @field_class.new({
        name: "html#{@html_count}",
        group: @group,
        field_type: :html,
        label: text
      }.merge(options))
    end
  end
  private_constant :ConfigDsl

  sig { returns(T::Array[String]) }
  private_class_method def self.config_files
    Dir.glob("#{::Rails.root}/config/extra_fields/*_fields.rb")
  end

  sig { params(kind: T.any(String, Symbol), config_file_path: String).returns(T::Array[UserField]) }
  private_class_method def self.load_fields(kind, config_file_path)
    return [] unless File.exist?(config_file_path)

    cls =
      case kind.to_s
      when 'user' then UserField
      else raise "Field class not found for kind #{kind}"
      end

    dsl = ConfigDsl.new(cls)
    dsl.instance_eval(File.read(config_file_path))
    dsl.fields
  end
end
