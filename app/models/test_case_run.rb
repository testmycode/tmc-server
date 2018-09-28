# frozen_string_literal: true

class TestCaseRun < ActiveRecord::Base
  belongs_to :submission
end
