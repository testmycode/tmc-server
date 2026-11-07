# typed: strict
# frozen_string_literal: true

# Provides operations for active records with a position field.
#
# Currently this is only used by FeedbackQuestion, and should probably
# go away if FeedbackQuestion is ever changed to use a config file.
module Orderable
  extend T::Sig
  extend ActiveSupport::Concern
  extend T::Helpers
  requires_ancestor { FeedbackQuestion }

  included do
    validates :position, uniqueness: true
    before_create :set_default_position
  end

  include Comparable

  sig { params(other: T.untyped).returns(T.nilable(Integer)) }
  def <=>(other)
    position <=> other.position
  end

  # Note on move commands:
  # - they operate on the database immediately
  # - any records that are not self and other may have a stale position afterwards

  sig { void }
  def move_forward!
    other = record_class.where("position > #{quote(position)}").order(:position).first
    move_after!(other) if other
  end

  sig { void }
  def move_backward!
    other = record_class.where("position < #{quote(position)}").order(position: :desc).first
    move_before!(other) if other
  end

  sig { params(other: FeedbackQuestion).void }
  def move_before!(other)
    move!(other, '<=', -1)
  end

  sig { params(other: FeedbackQuestion).void }
  def move_after!(other)
    move!(other, '>=', 1)
  end

  private
    sig { params(other: FeedbackQuestion, op: String, delta: Integer).void }
    def move!(other, op, delta)
      tbl = record_class.quoted_table_name
      conn = ActiveRecord::Base.connection
      conn.transaction(requires_new: true) do
        conn.execute("LOCK #{tbl} IN ACCESS EXCLUSIVE MODE")

        other_pos = conn.select_value("SELECT position FROM #{tbl} WHERE id = #{other.id}")
        raise 'Move target not found in database' if other_pos.nil?
        new_position = other_pos.to_i + delta

        if conn.select_value("SELECT 1 FROM #{tbl} WHERE position = #{new_position}")
          conn.execute("UPDATE #{tbl} SET position = position + (#{delta}) WHERE position #{op} #{new_position}")
        end

        conn.execute("UPDATE #{tbl} SET position = #{new_position} WHERE id = #{id}")
        self.position = new_position
      end
    end

    sig { void }
    def set_default_position
      if position.nil?
        tbl = record_class.quoted_table_name
        conn = ActiveRecord::Base.connection
        conn.execute("LOCK #{tbl} IN ACCESS EXCLUSIVE MODE") # applies to the rest of this transaction
        max = conn.select_value("SELECT MAX(position) FROM #{tbl}").to_i
        self.position = max + 1
      end
    end

    sig { params(value: T.untyped).returns(String) }
    def quote(value)
      record_class.connection.quote(value)
    end

    sig { returns(T.class_of(FeedbackQuestion)) }
    def record_class
      T.cast(self.class, T.class_of(FeedbackQuestion))
    end
end
