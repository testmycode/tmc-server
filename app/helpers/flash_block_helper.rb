# typed: strict
# frozen_string_literal: true

module FlashBlockHelper
  extend T::Sig

  sig { returns(ActiveSupport::SafeBuffer) }
  def flash_block
    output = ''
    flash.each do |type, message|
      output += flash_container(type, message)
    end

    raw(output)
  end

  # Flash values come back from the session as whatever a controller stored.
  sig { params(type: String, message: T.untyped).returns(ActiveSupport::SafeBuffer) }
  def flash_container(type, message)
    raw(content_tag(:div, class: "alert alert-#{type}") do
      content_tag(:a, raw('&times;'), class: 'close', data: { dismiss: 'alert' }) +
      message
    end)
  end
end
