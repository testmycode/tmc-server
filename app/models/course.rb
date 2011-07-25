require 'gdocs'

class Course < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include GitBackend

  self.include_root_in_json = false

  validates :name,
            :presence     => true,
            :uniqueness => true,
            :length       => { :within => 1..40 },
            :format       => { :without => / / ,
            :message => 'should not contain white spaces'}

  has_many :exercises, :dependent => :destroy
  has_many :awarded_points, :dependent => :destroy

  before_save lambda { self.remote_repo_url = nil if self.remote_repo_url.blank? }
  after_create :create_local_repository, :if => lambda { has_local_repo? }
  after_destroy :delete_local_repository, :if => lambda { has_local_repo? }

  def users
    User.find(:all,
              :joins => :awarded_points,
              :group => 'id',
              :conditions => { :awarded_points =>
                               { :course_id => self.id }})
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

  def create_spreadsheet_to_google
    account = GDocs.new
    account.create_new_spreadsheet(self.name)
  end

  def exercises_json
    "#{course_exercises_url(self)}.json"
  end

  def refresh_options
    options_file = "#{clone_path}/course_options.yml"
    options = Course.default_options

    if FileTest.exists? options_file
      options = options.merge(YAML.load_file(options_file))
    end

    if !options["hide_after"].blank?
      self.hide_after = Time.parse(options["hide_after"])
    else
      self.hide_after = nil
    end
  end

  def refresh_exercises
    read_exs = Exercise.read_exercises self.clone_path

    self.exercises.each do |old_e|
      read_e = read_exs.find {|x| x.name == old_e.name}
      if read_e
        old_e.copy_metadata read_e
        old_e.deleted = false
      else
        old_e.deleted = true
      end
      old_e.save!
    end

    read_exs.each do |read_e|
      if self.exercises.none? {|x| x.name == read_e.name}
        self.exercises << read_e
      end
    end

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
    {}
  end

end
