class Exercise < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  self.include_root_in_json = false

  belongs_to :course

  has_many :available_points, :dependent => :destroy
  has_many :submissions, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "submissions.course_id = #{self.course_id}" }

  validates :gdocs_sheet,
            :presence => true,
            :format => { :without => /^summary$/ }

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
      !deadline_passed? && !hidden?
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
  
  def options=(new_options)
    new_options = self.class.default_options.merge(new_options)
    self.deadline = new_options["deadline"]
    self.publish_date = new_options["publish_date"]
    self.gdocs_sheet = new_options["gdocs_sheet"]
  end
  
  def self.default_options
    {
      "deadline" => nil,
      "publish_date" => nil,
      "gdocs_sheet" => "root"
    }
  end
  
private

  def deadline_passed?
    self.deadline != nil && self.deadline < Time.now
  end

end
