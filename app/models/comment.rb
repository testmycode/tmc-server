# frozen_string_literal: true

class Comment < ApplicationController
  belongs_to :user
  belongs_to :submission

  def to_my_json
    hash = {
      user: { login: (user.nil? ? 'Guest' : user.login) },
      comment: comment
    }
    hash.as_json
  end
end
