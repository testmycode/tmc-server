# typed: strict

# frozen_string_literal: true

module BadUtf8Helper
  extend T::Sig

  # Returns `str` as valid UTF-8: as is if its bytes are UTF-8, otherwise decoded as Latin-1.
  sig { params(str: String).returns(String) }
  def force_utf8_violently(str)
    return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

    as_utf8 = str.dup.force_encoding(Encoding::UTF_8)
    return as_utf8 if as_utf8.valid_encoding?

    # Latin-1 maps every byte to a character, so this cannot fail.
    str.dup.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8)
  end
end
