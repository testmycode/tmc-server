require 'test_runner'

class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }

  has_many :test_case_runs, :dependent => :destroy
  has_many :awarded_points, :dependent => :nullify
  
  attr_accessor :return_file_tmp_path
  attr_accessor :skip_test_runner if ::Rails.env == 'test'
  
  validates :user, :presence => true
  validates :course, :presence => true
  validates :exercise_name, :presence => true
  
  def tests_ran?
    pretest_error == nil
  end
  
  def all_tests_passed?
    tests_ran? && test_case_runs.map(&:successful?).all?
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
  
  # @deprecated in favor of categorizing errors by test cases.
  # To be removed after #22 is resolved.
  # Btw remember to search for and remove possible stubs in tests too.
  def test_failure_messages
    test_case_runs.reject(&:successful?).map do |tcr|
      pretty_name = pretty_test_case_name(tcr.test_case_name)
      if tcr.message.blank?
        "#{pretty_name} - fail"
      else
        "#{pretty_name} - #{tcr.message}"
      end
    end
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
  
  def run_tests
    self.pretest_error = nil
    
    return if ::Rails.env == 'test' && self.skip_test_runner
    
    begin
      self.return_file = IO.read(return_file_tmp_path) if new_record?
      
      TestRunner.run_submission_tests(self)
    rescue
      if $!.message.start_with?("Compilation error") # haxy - should fix
        self.pretest_error = $!.message
      else
        self.pretest_error = $!.message + "\n" + $!.backtrace.join("\n")
      end
    end
  end
  
private
  
  def test_case_category_and_name(test_case_name)
    parts = test_case_name.split(/\s+/, 2)
    if parts.length == 2
      parts
    else
      ['', test_case_name]
    end
  end
  
  def pretty_test_case_name(long_name) #DEPRECATED - used by deprecated test_failure_messages
    if long_name =~ /^.+\.[^.]+ ([^.]+)$/
      method_name = $1
      method_name
    else
      long_name
    end
  end
end
