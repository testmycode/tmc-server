class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :exercise
  has_many :test_case_runs, :dependent => :destroy
  has_many :awarded_points, :dependent => :nullify
  
  attr_accessor :return_file_tmp_path
  
  before_create :run_tests
  
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
    "#{exercise.name}-#{self.id}.zip"
  end
  
  def test_failure_messages
    test_case_runs.reject(&:successful?).map {|tcr| "#{tcr.test_case_name} - #{tcr.message}" }
  end
  
private
  def run_tests
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
