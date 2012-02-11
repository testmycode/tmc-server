# See UserFieldValue
module ExtraFieldValue
  extend ActiveSupport::Concern

  included do
    validates :field_name, :uniqueness => {:scope => :user_id}
  end

  def field
    @field ||= ExtraField.by_kind(field_kind).select {|f| f.name == self.field_name }.first
  end

  def field_kind
    @field_kind ||= self.class.name.underscore.gsub(/_field_value$/, '').to_sym
  end

  def set_from_form(new_value)
    self.value =
      case field_kind
      when :boolean
        new_value.to_bool
      else
        new_value.to_s
      end
  end

end