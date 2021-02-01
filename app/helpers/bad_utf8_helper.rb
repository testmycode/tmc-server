
# frozen_string_literal: true

module BadUtf8Helper
  def force_utf8_violently(str)
    if str.encoding == Encoding.find('UTF-8') && str.valid_encoding?
      str
    else
      str.dup.force_encoding('ISO-8859-1')
      if str.valid_encoding?
        str.dup.encode('UTF-8')
      else
        str.dup.force_encoding('UTF-8')
        str.dup.encode('UTF-8', 'ASCII-8BIT', invalid: :replace, undef: :replace)
      end
    end
  end
end
