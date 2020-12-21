# frozen_string_literal: true

# Helpers for serving /stats.
module Stats
  def self.courses(organization = nil)
    courses = Course.all
    courses = courses.where(organization: organization) unless organization.nil?
    {
      registered_users: all_regular_users.count,
      course_stats: courses.reduce({}) { |h, c| h.merge(c.name => for_course(c)) }
    }
  end

  def self.for_course(course)
    keys = %i[
      participants_with_submissions_count
      completed_exercise_count
      possible_completed_exercise_count
      exercise_group_stats
    ]
    keys.reduce({}) { |h, k| h.merge(k => send(k, course)) }
  end

  def self.exercise_group_stats(course)
    result = {}
    for group_name, exercises in exercise_groups(course)
      result[group_name] = {
        participants_with_submissions_count: participants_with_submissions_count(exercises),
        completed_exercise_count: completed_exercise_count(exercises),
        possible_completed_exercise_count: possible_completed_exercise_count(exercises)
      }
    end
    result
  end

  def self.exercise_groups(course)
    groups = {}
    for exercise in course.exercises.where(hidden: false)
      groups[exercise.exercise_group_name] ||= []
      groups[exercise.exercise_group_name] << exercise
    end
    groups
  end

  def self.participants_with_submissions_count(exercise_or_course = nil)
    exercises = get_exercises(exercise_or_course)
    if exercises.present?
      exercise_keys = exercises.map { |e| "(#{e.course_id}, #{quote_value(e.name, nil)})" }
      exercises_clause = "AND (course_id, exercise_name) IN (#{exercise_keys.join(',')})"
      all_regular_users.where("EXISTS (SELECT 1 FROM submissions WHERE user_id = users.id #{exercises_clause})").count
    else
      0
    end
  end

  def self.completed_exercise_count(exercise_or_course = nil)
    exercises = get_exercises(exercise_or_course)
    Exercise.count_completed(all_regular_users, exercises)
  end

  def self.possible_completed_exercise_count(exercise_or_course = nil)
    exercises = get_exercises(exercise_or_course)
    participants_with_submissions_count(exercises) * exercises.size
  end

  private

    def self.all_regular_users
      User.where(administrator: false)
    end

    def self.all_nonhidden_exercises
      Exercise.where(hidden: false)
    end

    def self.get_exercises(exercise_or_course = nil)
      if exercise_or_course.nil?
        all_nonhidden_exercises
      elsif exercise_or_course.is_a?(Course)
        exercise_or_course.exercises.where(hidden: false)
      else
        exercise_or_course
      end
    end
end
