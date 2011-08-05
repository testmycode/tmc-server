class Guest < User
  before_save :reject_save
  
  def initialize(*args)
    super(*args)
    self.login = 'guest'
  end
  
  def guest?
    true
  end
  
private
  def reject_save
    raise 'The guest user cannot be saved!'
  end
end
