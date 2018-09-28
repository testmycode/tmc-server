# frozen_string_literal: true

class UserField
  include ExtraField

  def show_in_participant_list?
    @options[:show_in_participant_list]
  end

  def visible_to?(user)
    @options[:visible_to_if].call(user)
  end

  def default_options
    super.merge(show_in_participant_list: false,
                visible_to_if: ->(_user) { true })
  end
end
