require 'gdocs'

class Course < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include GitBackend

  validates :name, :presence     => true,
            :length       => { :within => 1..40 },
            :format       => { :without => / / ,
            :message => 'should not contain white spaces'}

  validates_uniqueness_of :name

  has_many :exercises, :dependent => :destroy
  #has_many :points, :dependent => :destroy
  after_create :create_repository #, :create_spreadsheet_to_google
  after_destroy :delete_repository

  def to_param
    self.name
  end

  def create_spreadsheet_to_google
    account = GDocs.new
    account.create_new_spreadsheet(self.name)
  end

  def exercises_json
    "#{course_exercises_url(self)}.json"
  end

  def self.default_options
    {
      "hide_after" => Time.at(0)
    }
  end

  def refresh_options
    options_file = "#{clone_path}/course_options.yml"
    options = Course.default_options

    if FileTest.exists? options_file
      options = options.merge(YAML.load_file(options_file))
    end

    self.hide_after = options["hide_after"]
  end

  def refresh_exercises
    read_exs = Exercise.read_exercises self.clone_path

    self.exercises.each do |old_e|
      read_e = read_exs.find {|x| x.name == old_e.name}
      if read_e
        old_e.update_attributes read_e
      else
        old_e.destroy
      end
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

end
