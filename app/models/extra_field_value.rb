# typed: strict
# frozen_string_literal: true

# An abstract base for active record classes representing values for 'ExtraField's.
#
# See UserFieldValue for an example.
module ExtraFieldValue
  extend T::Sig
  extend ActiveSupport::Concern
  extend T::Helpers
  requires_ancestor { UserFieldValue }

  included do
    validates :field_name, uniqueness: { scope: :user_id }
  end

  sig { returns(T.nilable(UserField)) }
  def field
    @field ||= T.let(ExtraField.by_kind(field_kind).find { |f| f.name == field_name }, T.nilable(UserField))
  end

  sig { returns(Symbol) }
  def field_kind
    @field_kind ||= T.let(T.must(self.class.name).underscore.gsub(/_field_value$/, '').to_sym, T.nilable(Symbol))
  end

  # Unfortunately, value is actually a string that can be put directly in a form.
  # May want to refactor some day.
  sig { returns(T.any(String, T::Boolean)) }
  def ruby_value
    case field&.field_type
    when :boolean
      value.blank? || value == '0' ? false : true
    else
      value
    end
  end

  sig { params(new_value: T.untyped).void }
  def set_from_form(new_value)
    field = self.field
    return unless field&.should_save?
    self.value =
      case field.field_type
      when :boolean
        ActiveModel::Type::Boolean.new.cast(new_value) ? '1' : ''
      else
        new_value.to_s
      end
  end
end
