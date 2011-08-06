require 'gdocs'

class Course < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include GitBackend

  self.include_root_in_json = false

  validates :name,
            :presence   => true,
            :uniqueness => true,
            :length     => { :within => 1..40 },
            :format     => {
              :without => / / ,
              :message  => 'should not contain white spaces'
            }

  has_many :exercises, :dependent => :destroy
  has_many :submissions, :dependent => :destroy
  has_many :available_points, :through => :exercises
  has_many :awarded_points, :dependent => :destroy

  before_save lambda { self.remote_repo_url = nil if self.remote_repo_url.blank? }
  after_create :create_local_repository, :if => lambda { has_local_repo? }
  after_destroy :delete_local_repository, :if => lambda { has_local_repo? }

  scope :ongoing, lambda { where(["hide_after IS NULL OR hide_after > ?", Time.now]) }
  scope :expired, lambda { where(["hide_after IS NOT NULL AND hide_after <= ?", Time.now]) }

  def visible?
    !hidden && (hide_after == nil || hide_after > Time.now)
  end

  def has_remote_repo?
    !remote_repo_url.nil?
  end

  def has_local_repo?
    !has_remote_repo?
  end

  def bare_path
    super if has_local_repo?
  end

  def bare_url
    if has_local_repo?
      super
    else
      remote_repo_url
    end
  end
  
  def hide_after=(x)
    super(DateAndTimeUtils.to_time(x, :prefer_end_of_day => true))
  end

  def create_spreadsheet_to_google
    account = GDocs.new
    account.create_new_spreadsheet(self.name)
  end

  def refresh_options
    options_file = "#{clone_path}/course_options.yml"
    options = Course.default_options

    if FileTest.exists? options_file
      options = options.merge(YAML.load_file(options_file))
    end

    if !options["hide_after"].blank?
      self.hide_after = options["hide_after"]
    else
      self.hide_after = nil
    end
    
    self.hidden = !!options['hidden']
  end

  def refresh_exercises
    exercise_names = Exercise.read_exercise_names self.clone_path
    exercise_names.each do |name|
      if self.exercises.none? {|x| x.name == name}
        self.exercises << Exercise.new(:name => name)
      end
    end

    self.exercises.each{|e| e.refresh}
    self.exercises.reload
    self.save
  end

  def refresh
    self.clear_cache
    self.refresh_working_copy
    self.refresh_options
    self.refresh_exercises
    self.refresh_exercise_archives
  end

  def self.default_options
    {
      :hidden => false,
      :hide_after => nil
    }
  end

end
