require 'gdocs_export'
require 'course_refresher'
require 'system_commands'
require 'date_and_time_utils'

class Course < ActiveRecord::Base
  include SystemCommands

  self.include_root_in_json = false

  validates :name,
            :presence   => true,
            :uniqueness => true,
            :length     => { :within => 1..40 },
            :format     => {
              :without => / /,
              :message  => 'should not contain white spaces'
            }

  validates :source_url, :presence => true
  validate :check_source_backend
  after_initialize :set_default_source_backend

  has_many :exercises, :dependent => :destroy
  has_many :submissions, :dependent => :destroy
  has_many :available_points, :through => :exercises
  has_many :awarded_points, :dependent => :destroy
  has_many :test_scanner_cache_entries, :dependent => :destroy

  after_destroy :delete_cache

  scope :ongoing, lambda { where(["hide_after IS NULL OR hide_after > ?", Time.now]) }
  scope :expired, lambda { where(["hide_after IS NOT NULL AND hide_after <= ?", Time.now]) }

  def visible?
    !hidden && (hide_after == nil || hide_after > Time.now)
  end

  def hide_after=(x)
    super(DateAndTimeUtils.to_time(x, :prefer_end_of_day => true))
  end

  def options=(new_options)
    if !new_options["hide_after"].blank?
      self.hide_after = new_options["hide_after"]
    else
      self.hide_after = nil
    end

    self.hidden = !!new_options['hidden']
    self.spreadsheet_key = new_options['spreadsheet_key']
  end

  def self.default_options
    {
      :hidden => false,
      :hide_after => nil
    }
  end

  def gdocs_sheets
    self.exercises.map(&:gdocs_sheet).reject(&:nil?).uniq
  end

  def refresh_gdocs_worksheet sheetname
    GDocsExport.refresh_course_worksheet_points self, sheetname
  end
  
  def self.cache_root
    "#{::Rails.root}/tmp/cache/course"
  end

  def cache_path
    "#{Course.cache_root}/#{self.name}-#{self.cache_version}"
  end
  
  # A clone of the course repository
  def clone_path
    "#{cache_path}/clone"
  end
  
  # Directory for solutions
  def solution_path
    "#{cache_path}/solution"
  end
  
  # Directory for stubs
  def stub_path
    "#{cache_path}/stub"
  end
  
  # Directory for zips of the stubs
  def zip_path
    "#{cache_path}/zip"
  end
  
  def refresh
    CourseRefresher.new.refresh_course(self)
  end
  
  def delete_cache
    FileUtils.rm_rf cache_path
  end
  
  def self.valid_source_backends
    ['git']
  end
  
  def self.default_source_backend
    'git'
  end
  
  
private
  def check_source_backend
    unless Course.valid_source_backends.include?(source_backend)
      errors.add(:source_backend, 'must be one of [' + Course.valid_source_backends.join(', ') + "]")
    end
  end
  
  def set_default_source_backend
    self.source_backend ||= Course.default_source_backend
  end
end

