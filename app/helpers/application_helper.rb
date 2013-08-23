require 'tailoring'

module ApplicationHelper
  def tailoring
    Tailoring.get
  end
  
  
  def labeled(label, tags = nil, options = {}, &block)
    if tags.is_a?(Hash) && options.empty?
      options = tags
      tags = nil
    end
    
    options = {
      :order => :label_first,
      :class => nil
    }.merge(options)
    
    tags = capture(&block) if tags == nil && block != nil
    tags = tags.html_safe
    
    if tags =~ /id\s*=\s*"([^"]+)"/
      target = ' for="' + $1 + '"'
    else
      raise 'Cannot label a tag without an id'
    end
    
    cls = []
    cls << options[:order].to_s
    cls << h(options[:class].to_s) if options[:class]
    cls = ' class="' + cls.join(' ') + '"'
    
    label_start = ('<label' + target + cls + '>').html_safe
    label_text = h(label)
    label_end = '</label>'.html_safe
    
    case options[:order]
    when :label_first
      label_start + label_text + tags + label_end
    when :label_last
      label_start + tags + label_text + label_end
    else
      raise 'invalid :order option for labeled()'
    end
  end
  
  def labeled_field(label, tags = nil, options = {}, &block)
    cls = ['field']
    cls << options[:super_class].split(" ") if options[:super_class]
    cls = ' class="' + cls.join(' ') + '"'
    raw("<div #{cls} >" + labeled(label, tags, options, &block) + '</div>')
  end

  def bs_labeled_field(label, field)
    str = label_tag label, nil, class: "control-label"
    str += raw("<div class=\"controls\">" +raw(field) + "</div>")
    raw(str)
  end
  
  def use_datatables(table_selector, options = {})
    options = {
      :bJQueryUI => true,
      :bSort => false
    }.merge options
    script =<<EOS
<script type="text/javascript">
<!--
$(document).ready(function() {
  $('#{escape_javascript table_selector}').dataTable(#{options.to_json});
});
//-->
</script>
EOS
    raw(script)
  end

  def link_back
    raw('<div class="link-back">' + link_to('Back', :back) + '</div>')
  end

end
