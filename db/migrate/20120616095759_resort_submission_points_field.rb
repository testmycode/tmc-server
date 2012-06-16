require 'natcmp'

class ResortSubmissionPointsField < ActiveRecord::Migration
  def up
    # find_each loads stuff in batches and allows the GC to work better
    # When I tried loading them all to memory at once (.each),
    # the GC hung for a very long time afterwards.
    Submission.select([:id, :points]).find_each do |s|
      s.update_attribute(:points, s.points_list.sort {|a, b| Natcmp.natcmp(a, b) }.join(' '))
    end
  end

  def down
  end
end
