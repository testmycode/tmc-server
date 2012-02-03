class FeedbackAnswer < ActiveRecord::Base
  belongs_to :feedback_question
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }
  belongs_to :submission

  validates_with Validators::FeedbackAnswerFormatValidator

  def self.numeric_answer_averages(exercise)
    result = {}
    connection.execute(numeric_answer_averages_query(exercise).to_sql).each do |record|
      result[record['qid'].to_i] = record['avg'].to_f
    end
    result
  end

private
  def self.numeric_answer_averages_query(exercise)
    answers = FeedbackAnswer.arel_table
    questions = FeedbackQuestion.arel_table

    query =
      answers.
      join(questions).on(answers[:feedback_question_id].eq(questions[:id])).
      project(
        questions[:id].as('qid'),
        Arel.sql('AVG(CAST(answer AS int))').as('avg')
      ).
      where(questions[:kind].matches('intrange%')).
      where(answers[:course_id].eq(exercise.course_id)).
      where(answers[:exercise_name].eq(exercise.name)).
      group(questions[:id])
    
    query
  end
end
