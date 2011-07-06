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
end
