require 'gdocs'

class Exercise < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  self.include_root_in_json = false

  belongs_to :course
  
  def submissions
    raise 'cannot access submissions with no course set' if course_id == nil
    raise 'cannot access submissions with no exercise name set' if name == nil
    if course && name
      Submission.where(:course_id => course_id, :exercise_name => name)
    end
  end
  #after_create :add_sheet_to_gdocs

  def path
    name.gsub('-', '/')
  end

  def zip_file_path
    "#{course.zip_path}/#{self.name}.zip"
  end
  
  def zip_url
    "#{course_exercise_url(self.course, self)}.zip"
  end

  def return_address
    "#{course_exercise_submissions_url(self.course, self)}.json"
  end

  def add_sheet_to_gdocs
    course_name = self.course.name

    account = GDocs.new
    account.add_new_worksheet(course_name, self.gdocs_sheet.to_s)
  end
  
  def attempted_by?(user)
    submissions.where(:user_id => user.id).exists?
  end
  
  def completed_by?(user)
    # We try to find a submission whose test case runs are all successful
    conn = ActiveRecord::Base.connection
    query = <<EOS
SELECT COUNT(*) AS total,
       SUM(CASE WHEN successful = #{conn.quote(true)} THEN 1 ELSE 0 END) AS good
FROM test_case_runs AS tcr
  JOIN submissions AS sub ON (sub.id = tcr.submission_id)
GROUP BY submission_id
HAVING sub.exercise_name = #{conn.quote self.name} AND
       sub.user_id = #{conn.quote user.id} AND
       good = total AND
       total > 0
LIMIT 1
EOS
    !conn.execute(query).empty?
  end

  def self.read_exercises course_path
    exercise_paths = Exercise.find_exercise_paths course_path
    exercises = []

    exercise_paths.each do |exercise_path|
      exercises.push Exercise.read_exercise course_path, exercise_path
    end

    return exercises
  end

  def copy_metadata from
    self.deadline = from.deadline
    self.publish_date = from.publish_date
    self.gdocs_sheet = from.gdocs_sheet
  end

private

  def self.path_to_name(root_path, exercise_path)
    name = exercise_path.gsub(/^#{root_path}\//, '')
    name = name.gsub('/', '-')
    return name
  end

  def self.default_options
    {
      "deadline" => nil,
      "publish_date" => nil,
      "gdocs_sheet" => nil
    }
  end

  def self.read_exercise course_path, exercise_path
    e = Exercise.new

    e.name = Exercise.path_to_name course_path, exercise_path

    options = Exercise.get_options course_path, exercise_path
    e.deadline = options["deadline"]
    e.publish_date = options["publish_date"]
    e.gdocs_sheet = options["gdocs_sheet"]

    return e
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
