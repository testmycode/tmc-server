class FeedbackQuestion < ActiveRecord::Base
  include Orderable

  belongs_to :course
  has_many :feedback_answers, :dependent => :delete_all
  
  validates :course, :presence => true
  validates :kind, :presence => true do validate_kind end
  validates :question, :presence => true

  def title_or_question
    title || question
  end

  def intrange?
    kind =~ intrange_regex
  end
  
  def intrange
    if kind =~ intrange_regex
      ($1.to_i)..($2.to_i)
    else
      raise 'not an intrange question'
    end
  end

  def record_for_api
    {
      :id => id,
      :question => question,
      :kind => kind
    }
  end
  
private
  def intrange_regex
    self.class.intrange_regex
  end
  
  def self.intrange_regex
    /^intrange\[(-?\d+)\.\.(-?\d+)\]$/
  end
  
  def validate_kind
    unless kind == 'text' || kind =~ intrange_regex 
      errors[:kind] << "invalid"
    end
  end
end
