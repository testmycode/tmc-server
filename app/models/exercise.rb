class Exercise < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  self.include_root_in_json = false

  belongs_to :course

  has_many :available_points, :dependent => :destroy
  has_many :submissions, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "submissions.course_id = #{self.course_id}" }

  validates :gdocs_sheet, :format => { :without => /^summary$/ }

  scope :course_gdocs_sheet_exercises, lambda { |course, gdocs_sheet|
    where(:course_id => course.id, :gdocs_sheet => gdocs_sheet)
  }

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

  def available_to?(user)
    if user.administrator?
      true
    else
      !expired? && !hidden?
    end
  end

  def visible_to?(user)
    if user.administrator?
      true
    else
      !hidden?
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
    super(DateAndTimeUtils.to_time(new_deadline, :prefer_end_of_day => true))
  end

  def expired?
    self.deadline != nil && self.deadline < Time.now
  end

  def options=(new_options)
    new_options = self.class.default_options.merge(new_options)
    self.deadline = new_options["deadline"]
    self.publish_date = new_options["publish_date"]
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
    sheetname.empty?? "root" : sheetname
  end

  def returnable?
    if returnable_forced != nil
      returnable_forced
    else
      File.exist?(fullpath) &&
        File.exist?("#{fullpath}/test") &&
        !(Dir.entries("#{fullpath}/test") - ['.', '..', '.gitkeep', '.gitignore']).empty?
    end
  end

  def self.default_options
    {
      "deadline" => nil,
      "publish_date" => nil,
      "gdocs_sheet" => nil,
      "points_visible" => true,
      "hidden" => false,
      "returnable" => nil
    }
  end

end
