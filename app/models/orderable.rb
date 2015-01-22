# Provides operations for active records with a position field.
#
# Currently this is only used by FeedbackQuestion, and should probably
# go away if FeedbackQuestion is ever changed to use a config file.
module Orderable
  extend ActiveSupport::Concern
  included do
    validates :position, uniqueness: true
    before_create :set_default_position
  end

  include Comparable

  def <=>(other)
    self.position <=> other.position
  end

  # Note on move commands:
  # - they operate on the database immediately
  # - any records that are not self and other may have a stale position afterwards

  def move_forward!
    other = self.class.where("position > #{quote(self.position)}").order('position ASC').first
    self.move_after!(other) if other
  end

  def move_backward!
    other = self.class.where("position < #{quote(self.position)}").order('position DESC').first
    self.move_before!(other) if other
  end

  def move_before!(other)
    move!(other, '<=', -1)
  end

  def move_after!(other)
    move!(other, '>=', 1)
  end

private
  def move!(other, op, delta)
    tbl = self.class.quoted_table_name
    conn = ActiveRecord::Base.connection
    conn.transaction(requires_new: true) do
      conn.execute("LOCK #{tbl} IN ACCESS EXCLUSIVE MODE")

      other_pos = conn.select_value("SELECT position FROM #{tbl} WHERE id = #{other.id}")
      raise 'Move target not found in database' if other_pos == nil
      new_position = other_pos.to_i + delta

      if conn.select_value("SELECT 1 FROM #{tbl} WHERE position = #{new_position}")
        conn.execute("UPDATE #{tbl} SET position = position + (#{delta}) WHERE position #{op} #{new_position}")
      end

      conn.execute("UPDATE #{tbl} SET position = #{new_position} WHERE id = #{self.id}")
      self.position = new_position
    end
  end

  def set_default_position
    if self.position == nil
      tbl = self.class.quoted_table_name
      conn = ActiveRecord::Base.connection
      conn.execute("LOCK #{tbl} IN ACCESS EXCLUSIVE MODE") # applies to the rest of this transaction
      max = conn.select_value("SELECT MAX(position) FROM #{tbl}").to_i
      self.position = max + 1
    end
  end

  def quote(value)
    self.class.connection.quote(value)
  end
end
