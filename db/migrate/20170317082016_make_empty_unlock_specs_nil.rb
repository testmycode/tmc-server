class MakeEmptyUnlockSpecsNil < ActiveRecord::Migration
  def up
    Exercise.transaction do
      Exercise.find_each do |exercise|
        unlock = UnlockSpec.from_str(exercise.course, exercise.unlock_spec)
        exercise.update!(unlock_spec: nil) if unlock.empty?
      end
    end
  end
end
