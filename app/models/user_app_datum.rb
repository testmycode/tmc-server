# typed: strict
# frozen_string_literal: true

class UserAppDatum < ApplicationRecord
  extend T::Sig

  belongs_to :user

  # Writes a persisted user's fields in one namespace atomically, so concurrent writes of the same field can't race to insert it.
  sig { params(user_id: Integer, namespace: String, values_by_field_name: T::Hash[String, T.untyped]).void }
  def self.upsert_values(user_id:, namespace:, values_by_field_name:)
    return if values_by_field_name.empty?
    rows = values_by_field_name.map do |field_name, value|
      { user_id: user_id, namespace: namespace, field_name: field_name, value: value }
    end
    upsert_all(rows, unique_by: %i[user_id field_name namespace])
  end
end
