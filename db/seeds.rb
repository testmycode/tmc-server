User.create!(:login => 'admin', :password => 'admin', :administrator => true, :email => 'admin@example.com', :legitimate_student =>false)
User.create!(:login => 'test', :password => 'test', :administrator => false, :email => 'test@example.com')

SubmissionStatus.create!(:value => "attempted", :number => 1)
SubmissionStatus.create!(:value => "completed", :number => 2)
