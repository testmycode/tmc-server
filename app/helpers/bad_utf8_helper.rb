
module BadUtf8Helper
  def force_utf8_violently(str)
    str.encode('UTF-8', 'ASCII-8BIT', :invalid => :replace, :undef => :replace)
  end
end