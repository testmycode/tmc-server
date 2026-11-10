# typed: strict
# frozen_string_literal: true

module BootstrapFlashHelper
  extend T::Sig
  ALERT_TYPES = %i[error info success danger].freeze

  sig { returns(ActiveSupport::SafeBuffer) }
  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = :success if type.to_sym == :notice
      type = :danger if type.to_sym == :alert

      next unless ALERT_TYPES.include?(type.to_sym)

      Array(message).each do |msg|
        text = content_tag(:div,
                           content_tag(:button, raw('&times;'), :class => 'close', 'data-dismiss' => 'alert') +
                           msg, class: "alert alert-#{type}")
        flash_messages << text if message
      end
    end
    safe_join(flash_messages, "\n")
  end
end
