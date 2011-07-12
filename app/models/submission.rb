class Submission < ActiveRecord::Base

  validates :student_id, :presence     => true,
            :length       => { :within => 1..40 },
            :format       => { :without => / / , :message => 'should not contain whitespace'}

  belongs_to :exercise
  has_many :test_case_runs, :dependent => :destroy
  
  before_create :run_tests
  
  attr_accessor :return_file_tmp_path
  
  def tests_ran?
    pretest_error == nil
  end
  
  def all_tests_passed?
    @fully_successful |= tests_ran? && test_case_runs.map(&:success?).all?
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
  
private
  def run_tests
    begin
      self.return_file = IO.read(return_file_tmp_path)
    
      TestRunner.run_submission_tests(self)
      raise 'No test cases found' if test_case_runs.empty?
      
      Point.check_points(self)
    rescue
      if $!.message.start_with?("Compilation error") # haxy - should fix
        self.pretest_error = $!.message
      else
        self.pretest_error = $!.message + "\n" + $!.backtrace.join("\n")
      end
    end
  end
end
