class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :submission

  def to_my_json
    hash = {
      user: {login: (self.user.nil? ? 'Guest' : self.user.login)},
      comment: self.comment
    }
    hash.as_json
  end
end
