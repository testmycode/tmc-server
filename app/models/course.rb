require 'gdocs_export'
require 'system_commands'
require 'date_and_time_utils'

class Course < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include SystemCommands
  include Course::GitCache

  self.include_root_in_json = false

  validates :name,
            :presence   => true,
            :uniqueness => true,
            :length     => { :within => 1..40 },
            :format     => {
              :without => / /,
              :message  => 'should not contain white spaces'
            }

  has_many :exercises, :dependent => :destroy
  has_many :submissions, :dependent => :destroy
  has_many :available_points, :through => :exercises
  has_many :awarded_points, :dependent => :destroy

  before_save lambda { self.remote_repo_url = nil if self.remote_repo_url.blank? }
  after_create :create_local_repository, :if => lambda { has_local_repo? }
  after_destroy :delete_local_repository, :if => lambda { has_local_repo? }
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

  def refresh_gdocs
    GDocsExport.refresh_course_points self
  end

end

