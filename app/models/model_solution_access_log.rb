# frozen_string_literal: true

class ModelSolutionAccessLog < ApplicationController
  belongs_to :user
  belongs_to :course
end
