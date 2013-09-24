module FilesHelper

  def valid_encoding!(text)
    return text if text.valid_encoding?
    text.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
  end

end