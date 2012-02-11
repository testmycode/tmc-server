module ExtraFieldHelper
  def extra_field(field_value, method_options)
    field = field_value.field
    return '' if field.options[:hidden]

    field_name = field.name
    field_name = "#{method_options[:form_scope]}[#{field_name}]" if method_options[:form_scope]

    common_attrs = {}
    common_attrs[:disabled] = 'disabled' if field.options[:disabled]

    existing_value = field_value.value
    existing_value = field.default if existing_value == nil

    field_tag =
      case field.field_type
      when :text
        text_field_tag(field_name, existing_value, common_attrs)
      when :boolean
        check_box_tag(field_name, '1', !existing_value.blank?, common_attrs)
      else
        raise "Unknown extra field type: #{field.field_type}"
      end
    
    labeled_field(field.label, field_tag)
  end
end
