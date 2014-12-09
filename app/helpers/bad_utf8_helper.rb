
module BadUtf8Helper
  def force_utf8_violently(str)
    if str.encoding == Encoding.find('UTF-8') && str.valid_encoding?
      str
    else
      str.force_encoding('ISO-8859-1')
      if str.valid_encoding?
        str.encode('UTF-8')
      else
        str.force_encoding('UTF-8')
        str.encode('UTF-8', 'ASCII-8BIT', invalid: :replace, undef: :replace)
      end
    end
  end
end
