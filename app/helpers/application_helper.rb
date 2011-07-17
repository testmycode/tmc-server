module ApplicationHelper
  def labeled(label, tags)
    if tags =~ /id\s*=\s*"([^"]+)"/
      raw('<label for="' + h($1) + '">' + h(label) + '</label>' + tags)
    else
      raise 'Cannot label a tag without an id'
    end
  end
  
  def labeled_field(label, tags)
    raw('<div class="field">' + labeled(label, tags) + '</div>')
  end
  
  def use_datatables(table_selector)
    script =<<EOS
<script type="text/javascript">
<!--
$(document).ready(function() {
  $('#{escape_javascript table_selector}').dataTable({
    bJQueryUI: true
  });
});
//-->
</script>
EOS
    raw(script)
  end
end
