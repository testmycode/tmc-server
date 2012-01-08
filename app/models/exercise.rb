class Exercise < ActiveRecord::Base
  include Comparable
  include Rails.application.routes.url_helpers

  self.include_root_in_json = false

  belongs_to :course

  has_many :available_points, :dependent => :destroy
  has_many :submissions, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "submissions.course_id = #{self.course_id}" }

  validates :gdocs_sheet, :format => { :without => /^(MASTER|PUBLIC)$/ }

  scope :course_gdocs_sheet_exercises, lambda { |course, gdocs_sheet|
    where(:course_id => course.id, :gdocs_sheet => gdocs_sheet)
  }

  def relative_path
    name.gsub('-', '/')
  end

  def clone_path
    "#{course.clone_path}/#{self.relative_path}"
  end

  def solution_path
    "#{course.solution_path}/#{self.relative_path}"
  end

  def stub_path
    "#{course.stub_path}/#{self.relative_path}"
  end

  def zip_file_path
    "#{course.zip_path}/#{self.name}.zip"
  end

  def zip_url
    "#{course_exercise_url(self.course, self)}.zip"
  end

  def return_url
    "#{course_exercise_submissions_url(self.course, self)}.json"
  end
  
  def solution
    Solution.new(self)
  end

  # Whether a user may make submissions
  def submittable_by?(user)
    returnable? && if user.administrator?
      true
    else
      !expired? && !hidden? && published? && !user.guest?
    end
  end

  # Whether a user may see the exercise
  def visible_to?(user)
    if user.administrator?
      true
    else
      !hidden? && published?
    end
  end
 
  # Whether the exercise has been published (it may still be hidden)
  def published?
    !publish_time || publish_time <= Time.now
  end

  # Whether a user has made a submission for this exercise
  def attempted_by?(user)
    submissions.where(:user_id => user.id).exists?
  end

  # Whether a user has made a submission with all test cases passing
  def completed_by?(user)
    # We try to find a submission whose test case runs are all successful
    conn = ActiveRecord::Base.connection
    query = <<EOS
SELECT 1
FROM test_case_runs AS tcr
  JOIN submissions AS sub ON (sub.id = tcr.submission_id)
WHERE sub.exercise_name = #{conn.quote self.name} AND
      sub.user_id = #{conn.quote user.id}
GROUP BY submission_id
HAVING COUNT(*) = SUM(CASE WHEN successful = #{conn.quote(true)} THEN 1 ELSE 0 END) AND
       COUNT(*) > 0
LIMIT 1
EOS
    !conn.execute(query).to_a.empty?
  end

  def deadline=(new_deadline)
    super(DateAndTimeUtils.to_time(new_deadline, :prefer_end_of_day => true))
  end

  # Whether the deadline has passed
  def expired?
    self.deadline != nil && self.deadline < Time.now
  end

  def options=(new_options)
    new_options = self.class.default_options.merge(new_options)
    self.deadline = new_options["deadline"]
    self.publish_time = new_options["publish_time"]
    self.gdocs_sheet = new_gdocs_sheet(new_options["points_visible"],
                                       new_options["gdocs_sheet"])
    self.hidden = new_options["hidden"]
    self.returnable_forced = new_options["returnable"]
  end

  def new_gdocs_sheet enabled, sheetname
    return nil unless enabled
    return sheetname unless sheetname.nil? or sheetname.empty?
    return self.name2gdocs_sheet
  end

  def name2gdocs_sheet
    sheetname = self.name.split('-')[0..-2].join('-')
    sheetname.empty? ? "root" : sheetname
  end

  # Whether this exercise accepts submissions at all.
  # TMC may be used to distribute exercise templates without tests.
  def returnable?
    if returnable_forced != nil
      returnable_forced
    else
      File.exist?(clone_path) &&
        File.exist?("#{clone_path}/test") &&
        !(Dir.entries("#{clone_path}/test") - ['.', '..', '.gitkeep', '.gitignore']).empty?
    end
  end

  def self.default_options
    {
      "deadline" => nil,
      "publish_time" => nil,
      "gdocs_sheet" => nil,
      "points_visible" => true,
      "hidden" => false,
      "returnable" => nil
    }
  end

  def <=>(other)
    self.name <=> other.name
  end
end
