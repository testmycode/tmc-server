# Stores what the student has answered to a single feedback question (for an exercise in a course).
class FeedbackAnswer < ActiveRecord::Base
  belongs_to :feedback_question
  belongs_to :course
  belongs_to :exercise, -> { where("exercises.course_id = #{self.course_id}") }, :foreign_key => :exercise_name, :primary_key => :name
  belongs_to :submission
  has_many :reply_to_feedback_answers, :dependent => :delete_all

  validates_with Validators::FeedbackAnswerFormatValidator

  def replied?
    reply_to_feedback_answers.count > 0
  end

  def self.numeric_answer_averages(exercise)
    result = {}
    connection.execute(numeric_answer_averages_query(exercise).to_sql).each do |record|
      result[record['qid'].to_i] = record['avg'].to_f
    end
    result
  end

  def self.anonymous_numeric_answers(exercise)
    by_submission = {}
    connection.execute(numeric_answers_query(exercise).to_sql).each do |record|
      sid = record['sid'].to_i
      qid = record['qid'].to_i
      answer = record['answer'].to_i

      by_submission[sid] ||= {}
      by_submission[sid][qid] = answer
    end

    by_submission.values.shuffle! # shuffled to minimize user identifiability
  end

private
  def self.numeric_answers_query(exercise)
    questions = FeedbackQuestion.arel_table
    answers = FeedbackAnswer.arel_table

    numeric_answers_base_query(exercise).
      project(
        questions[:id].as('qid'),
        answers[:submission_id].as('sid'),
        Arel.sql('CAST(answer AS int)').as('answer')
      )
  end

  def self.numeric_answer_averages_query(exercise)
    questions = FeedbackQuestion.arel_table

    numeric_answers_base_query(exercise).
      group(questions[:id]).
      project(
        questions[:id].as('qid'),
        Arel.sql('AVG(CAST(answer AS int))').as('avg')
      )
  end

  def self.numeric_answers_base_query(exercise)
    answers = FeedbackAnswer.arel_table
    questions = FeedbackQuestion.arel_table

    answers.
      join(questions).on(answers[:feedback_question_id].eq(questions[:id])).
      where(questions[:kind].matches('intrange%')).
      where(answers[:course_id].eq(exercise.course_id)).
      where(answers[:exercise_name].eq(exercise.name))
  end
end
