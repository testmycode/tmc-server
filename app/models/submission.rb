
class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }

  has_many :test_case_runs, :dependent => :destroy
  has_many :awarded_points, :dependent => :nullify
  
  validates :user, :presence => true
  validates :course, :presence => true
  validates :exercise_name, :presence => true
  
  def self.to_be_reprocessed
    self.where(:processed => false).where('updated_at < ?', Time.now - reprocess_attempt_interval).order(:id)
  end
  
  def self.unprocessed_count
    self.where(:processed => false).count
  end
  
  before_create :randomize_secret_token
  
  def tests_ran?
    processed? && pretest_error == nil
  end
  
  def all_tests_passed?
    tests_ran? && test_case_runs.map(&:successful?).all?
  end
  
  def status
    if !processed?
      :processing
    elsif all_tests_passed?
      :ok
    elsif tests_ran?
      :fail
    else
      :error
    end
  end
  
  def unprocessed_submissions_before_this
    if !self.processed?
      self.class.where(:processed => false).where('id < ?', self.id).count
    else
      nil
    end
  end
  
  def downloadable_file_name
    "#{exercise_name}-#{self.id}.zip"
  end
  
  def categorized_test_failures
    result = {}
    test_case_runs.reject(&:successful?).each do |tcr|
      category, name = test_case_category_and_name(tcr.test_case_name)
      msg = tcr.message
      msg = 'fail' if msg.blank?
      result[category] ||= []
      result[category] << "#{name} - #{msg}"
    end
    result
  end
  
  # When a remote sandbox returns a result to the webapp,
  # it authenticates the result by passing back the secret token.
  # Changing it in the meantime will obsolete any runs currently being processed.
  def randomize_secret_token
    self.secret_token = rand(10**100).to_s
  end
  
private
  
  def self.reprocess_attempt_interval
    10.seconds
  end
  
  def test_case_category_and_name(test_case_name)
    parts = test_case_name.split(/\s+/, 2)
    if parts.length == 2
      parts
    else
      ['', test_case_name]
    end
  end
end
