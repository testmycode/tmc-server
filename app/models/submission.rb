
class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }

  has_many :test_case_runs, :dependent => :destroy, :order => :id
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
  
  def result_url
    "#{SiteSetting.value(:baseurl_for_remote_sandboxes).sub(/\/+$/, '')}/submissions/#{self.id}/result"
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
  
  def points_list
    points.to_s.split(' ')
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
  
  def test_case_records
    test_case_runs.map do |tcr|
      {
        :name => tcr.test_case_name,
        :successful => tcr.successful?,
        :message => tcr.message,
        :exception => if tcr.exception then ActiveSupport::JSON.decode(tcr.exception) else nil end
      }
    end
  end
  
  # When a remote sandbox returns a result to the webapp,
  # it authenticates the result by passing back the secret token.
  # Changing it in the meantime will obsolete any runs currently being processed.
  def randomize_secret_token
    self.secret_token = rand(10**100).to_s
  end
  
private
  
  def self.reprocess_attempt_interval
    20.seconds # TODO: fix https://github.com/testmycode/tmc-server/issues/71
  end
end
