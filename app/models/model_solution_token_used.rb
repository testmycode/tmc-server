# frozen_string_literal: true

class ModelSolutionTokenUsed < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :exercise_name, presence: true
end
