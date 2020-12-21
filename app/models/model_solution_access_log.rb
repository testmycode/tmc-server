# frozen_string_literal: true

class ModelSolutionAccessLog < ApplicationRecord
  belongs_to :user
  belongs_to :course
end
