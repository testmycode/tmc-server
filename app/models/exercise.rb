require 'gdocs'

class Exercise < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  self.include_root_in_json = false

  belongs_to :course

  has_many :points, :dependent => :destroy
  has_many :submissions, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "submissions.course_id = #{self.course_id}" }

  def path
    name.gsub('-', '/')
  end

  def fullpath
    "#{course.clone_path}/#{self.path}"
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
  
  def available_to?(user)
    if user == nil || !user.administrator?
      !deadline_passed?
    else
      true
    end
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
  
  def deadline=(new_deadline)
    d = new_deadline
    if d.blank?
      super(nil)
      return
    end
    
    d = DateAndTimeUtils.parse_date_or_time(d) if d.is_a?(String)
    
    if d.is_a? Date
      d = d.end_of_day
    elsif !d.is_a?(Time)
      raise "Invalid deadline: #{new_deadline}"
    end
    super(d)
  end

  def refresh
    unless Exercise.exercise_path? self.fullpath
      self.destroy
      return
    end

    refresh_options
    refresh_points
    self.save
  end

  def refresh_options
    options = Exercise.get_options course.clone_path, self.fullpath
    self.deadline = options["deadline"]
    self.publish_date = options["publish_date"]
    self.gdocs_sheet = options["gdocs_sheet"]
  end

  def refresh_points
    point_names = Point.read_point_names(self.fullpath)

    point_names.each do |name|
      if self.points.none?{|point| point.name == name}
        Point.create(:name => name, :exercise => self)
      end
    end

    self.points.each do |point|
      if point_names.none?{|name| name == point.name}
        point.destroy
      end
    end
  end

  def self.read_exercise_names course_path
    Exercise.find_exercise_paths(course_path).map do |ex_path|
      Exercise.path_to_name(course_path, ex_path)
    end
  end

  def self.path_to_name(root_path, exercise_path)
    name = exercise_path.gsub(/^#{root_path}\//, '')
    name = name.gsub('/', '-')
    return name
  end

private

  def deadline_passed?
    self.deadline != nil && self.deadline < Time.now
  end

  def self.default_options
    {
      "deadline" => nil,
      "publish_date" => nil,
      "gdocs_sheet" => nil
    }
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

  def self.exercise_path? path
    FileTest.directory? path and FileTest.exists? "#{path}/src" and
      FileTest.exists? "#{path}/test" and FileTest.exists? "#{path}/nbproject"
  end

  def self.find_exercise_paths root_path
    exercise_paths = []

    Find.find(root_path) do |path|
      if Exercise.exercise_path? path
        exercise_paths << path
      end
    end

    return exercise_paths
  end
end
