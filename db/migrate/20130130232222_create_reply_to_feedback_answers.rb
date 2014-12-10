class CreateReplyToFeedbackAnswers < ActiveRecord::Migration
  def change
    create_table :reply_to_feedback_answers do |t|
      t.references :feedback_answer
      t.text       :body
      t.string     :from

      t.timestamps
    end
  end
end
