# typed: strict
# frozen_string_literal: true

module HtmlPreludeHelper
  extend T::Sig

  ALLOWED_TAGS = T.let(
    (Rails::HTML5::SafeListSanitizer.allowed_tags + %w[table thead tbody tfoot tr th td caption]).freeze,
    T::Set[String]
  )
  ALLOWED_ATTRIBUTES = T.let(
    (Rails::HTML5::SafeListSanitizer.allowed_attributes + %w[style colspan rowspan]).freeze,
    T::Set[String]
  )

  # Renders a teacher-written HTML prelude of an exercise file, keeping formatting but dropping scripts.
  sig { params(html_prelude: String).returns(ActiveSupport::SafeBuffer) }
  def sanitize_html_prelude(html_prelude)
    T.cast(sanitize(html_prelude, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES), ActiveSupport::SafeBuffer)
  end
end
