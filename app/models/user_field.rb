# typed: strict
# frozen_string_literal: true

class UserField
  extend T::Sig
  include ExtraField

  sig { returns(T::Boolean) }
  def show_in_participant_list?
    @options[:show_in_participant_list]
  end

  sig { params(user: User).returns(T::Boolean) }
  def visible_to?(user)
    @options[:visible_to_if].call(user)
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def default_options
    super.merge(show_in_participant_list: false,
                visible_to_if: ->(_user) { true })
  end
end
