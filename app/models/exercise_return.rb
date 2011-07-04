class ExerciseReturn < ActiveRecord::Base

 #does validates, but doesn't give error info given here
  validates :student_id, :presence     => true,
            :length       => { :within => 1..40 },
            :format       => { :without => / / ,
            :message => 'should not contain white spaces'}

  belongs_to :exercise
  has_many :test_suite_runs, :dependent => :destroy
end
