module Stats
  def self.all
    {
      :registered_users => all_regular_users.count,
      :course_stats => Course.all.reduce({}) {|h, c| h.merge(c.name => for_course(c)) }
    }
  end
  
  def self.for_course(course)
    keys = [
      :participants_with_submissions_count,
      :completed_exercise_count,
      :possible_completed_exercise_count,
      :exercise_group_stats
      ]
    keys.reduce({}) {|h, k| h.merge(k => self.send(k, course)) }
  end
  
  def self.exercise_group_stats(course)
    result = {}
    for group_name, exercises in exercise_groups(course)
      result[group_name] = {
        :participants_with_submissions_count => participants_with_submissions_count(exercises),
        :completed_exercise_count => completed_exercise_count(exercises),
        :possible_completed_exercise_count => possible_completed_exercise_count(exercises)
      }
    end
    result
  end
  
  def self.exercise_groups(course)
    groups = {}
    for exercise in course.exercises.where(:hidden => false)
      groups[exercise.category] ||= []
      groups[exercise.category] << exercise
    end
    groups
  end
  
  def self.participants_with_submissions_count(exercises = nil)
    exercises = exercises.exercises.where(:hidden => false) if exercises.is_a?(Course)
    if exercises && !exercises.empty?
      exercise_names = exercises.map {|e| ActiveRecord::Base.quote_value(e.name) }
      exercises_clause = "AND exercise_name IN (#{exercise_names.join(',')})"
    else
      exercises_clause = ''
    end
    all_regular_users.where("EXISTS (SELECT 1 FROM submissions WHERE user_id = users.id #{exercises_clause})").count
  end
  
  def self.completed_exercise_count(exercises = nil)
    exercises = exercises.exercises.where(:hidden => false) if exercises.is_a?(Course)
    exercises = all_nonhidden_exercises if exercises == nil
    count = 0
    for user in all_regular_users
      for exercise in exercises
        count += 1 if exercise.completed_by?(user)
      end
    end
    count
  end
  
  def self.possible_completed_exercise_count(exercises = nil)
    exercises = exercises.exercises.where(:hidden => false) if exercises.is_a?(Course)
    exercises = all_nonhidden_exercises if exercises == nil
    participants_with_submissions_count(exercises) * exercises.size
  end
  
private
  def self.all_regular_users
    User.where(:administrator => false)
  end
  
  def self.all_nonhidden_exercises
    Exercise.where(:hidden => false)
  end
end

