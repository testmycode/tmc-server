require 'natcmp'

class ResortSubmissionPointsField < ActiveRecord::Migration[4.2]
  def up
    result = execute("SELECT id, points FROM submissions")
    result.each do |row|
      id = row['id']
      points = row['points']
      if points != nil && points.include?(' ')
        new_points = points.to_s.split(' ').sort {|a, b| Natcmp.natcmp(a, b) }.join(' ')
        execute("UPDATE submissions SET points = #{connection.quote(new_points)} WHERE id = #{id.to_i}")
      end
    end
  end

  def down
  end
end
