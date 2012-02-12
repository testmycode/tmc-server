module ExtraFieldHelper
  def extra_field(field_value, method_options)
    field = field_value.field
    
    return '' if field.options[:hidden]
    return raw(field.label) if field.field_type == :html

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

    label_order =
      case field.field_type
      when :boolean
        :label_last
      else
        :label_first
      end

    labeled_field(raw(field.label), field_tag, :order => label_order)
  end

  def extra_field_filter(prefix, field, value)
    return '' if field.field_type == :html

    field_name = prefix + field.name

    field_tag =
      case field.field_type
      when :text
        text_field_tag(field_name, value)
      when :boolean
        check_box_tag(field_name, '1', !value.blank?)
      else
        raise "Unknown extra field type: #{field.field_type}"
      end

    label_order =
      case field.field_type
      when :boolean
        :label_last
      else
        :label_first
      end

    labeled_field(raw(field.name.humanize), field_tag, :order => label_order)
  end
end
