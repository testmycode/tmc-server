require 'gdocs'

class Exercise < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :course
  has_many :exercise_returns, :dependent => :destroy
  has_many :exercise_points, :dependent => :destroy
  #after_save :add_sheet_to_gdocs

  #def to_param
    #self.name
  #end

  def path
    name.gsub(/-/, '/')
  end

  def exercise_file
    "#{course_exercise_url(self.course, self)}.zip"
  end

  def return_address
    course_exercise_returns_url(self.course, self)
  end

  def add_sheet_to_gdocs
    course_name = self.course.name

    account = GDocs.new
    account.add_new_worksheet(course_name, self.gdocs_sheet.to_s)
  end

  def self.path_to_name root_path, exercise_path
    name = exercise_path.gsub(/^#{root_path}\//, '')
    name = name.gsub(/\//, '-')
    return name
  end

  def self.default_options
    {
      "deadline" => Time.at(0),
      "publish_date" => Time.at(0),
      "gdocs_sheet" => "101"
    }
  end

  def self.read_exercises course_path
    exercise_paths = Exercise.find_exercise_paths course_path
    exercises = []

    exercise_paths.each do |exercise_path|
      exercises.push Exercise.read_exercise course_path, exercise_path
    end

    return exercises
  end

  def self.read_exercise course_path, exercise_path
    e = Exercise.new

    e.name = Exercise.path_to_name course_path, exercise_path

    options = Exercise.get_options course_path, exercise_path
    e.deadline = options["deadline"]
    e.publish_date = options["publish_date"]
    e.gdocs_sheet = options["gdocs_sheet"]

    e.exercise_points = ExercisePoint.extract_exercise_points exercise_path

    return e
  end

  def update_attributes from
    self.deadline = from.deadline
    self.publish_date = from.publish_date
    self.gdocs_sheet = from.gdocs_sheet
  end

  def self.merge_file hash, file
    if FileTest.exists? file
      new_hash = YAML.load_file(file)
      hash = hash.merge(new_hash)
    end
    return hash
  end

  def self.get_options root_path, exercise_path
    subpath = exercise_path.gsub(/^#{root_path}\//, '')
    subdirs = subpath.split("/")
    options = Exercise.default_options
    options = Exercise.merge_file options, "#{root_path}/metadata.yml"

    subdirs.each_index do |i|
      options_file = "#{root_path}/#{subdirs[0..i].join('/')}/metadata.yml"
      options = Exercise.merge_file options, options_file
    end

    return options
  end

  def self.find_exercise_paths root_path
    exercise_paths = []

    Find.find(root_path) do |path|
      next if !FileTest.directory? path
      next if !FileTest.exists? "#{path}/src"
      next if !FileTest.exists? "#{path}/test"
      next if !FileTest.exists? "#{path}/nbproject"
        exercise_paths << path
    end

    return exercise_paths
  end
end
