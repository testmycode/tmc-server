User.create!(:login => 'admin', :password => 'admin', :administrator => true, :email => 'admin@example.com', legitimate_student: false)
User.create!(:login => 'test', :password => 'test', :administrator => false, :email => 'test@example.com')

