# An abstract base for active record classes representing values for 'ExtraField's.
#
# See UserFieldValue for an example.
module ExtraFieldValue
  extend ActiveSupport::Concern

  included do
    validates :field_name, uniqueness: { scope: :user_id }
  end

  def field
    @field ||= ExtraField.by_kind(field_kind).find { |f| f.name == field_name }
  end

  def field_kind
    @field_kind ||= self.class.name.underscore.gsub(/_field_value$/, '').to_sym
  end

  # Unfortunately, value is actually a string that can be put directly in a form.
  # May want to refactor some day.
  def ruby_value
    case field.field_type
    when :boolean
      if value.blank? || value == '0' then false else true end
    else
      value
    end
  end

  def set_from_form(new_value)
    if field.should_save?
      self.value =
        case field_kind
        when :boolean
          new_value.to_bool
        else
          new_value.to_s
        end
    end
  end
end
