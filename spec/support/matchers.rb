# frozen_string_literal: true

RSpec::Matchers.define :require_review do
  match(&:requires_review?)
end
