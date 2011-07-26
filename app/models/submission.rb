class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  has_many :test_case_runs, :dependent => :destroy
  has_many :awarded_points, :dependent => :nullify
  
  attr_accessor :return_file_tmp_path
  attr_accessor :skip_test_runner if ::Rails.env == 'test'
  
  validates :user, :presence => true
  validates :course, :presence => true
  validates :exercise_name, :presence => true
  
  before_create :run_tests
  
  def exercise
    Exercise.find_by_course_id_and_name(self.course_id, self.exercise_name)
  end
  
  def exercise=(ex)
    self.exercise_name = ex.name
  end
  
  def tests_ran?
    pretest_error == nil
  end
  
  def all_tests_passed?
    @fully_successful |= tests_ran? && test_case_runs.map(&:successful?).all?
  end
  
  def status
    if all_tests_passed?
      :ok
    elsif tests_ran?
      :fail
    else
      :error
    end
  end
  
  def downloadable_file_name
    "#{exercise_name}-#{self.id}.zip"
  end
  
  def test_failure_messages
    test_case_runs.reject(&:successful?).map {|tcr| "#{tcr.test_case_name} - #{tcr.message}" }
  end
  
private
  def run_tests
    return if ::Rails.env == 'test' && self.skip_test_runner
    begin
      self.return_file = IO.read(return_file_tmp_path)
    
      TestRunner.run_submission_tests(self)
    rescue
      if $!.message.start_with?("Compilation error") # haxy - should fix
        self.pretest_error = $!.message
      else
        self.pretest_error = $!.message + "\n" + $!.backtrace.join("\n")
      end
    end
  end
end
