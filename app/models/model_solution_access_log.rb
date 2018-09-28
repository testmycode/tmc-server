# frozen_string_literal: true

class ModelSolutionAccessLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
end
