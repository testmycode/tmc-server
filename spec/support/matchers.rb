RSpec::Matchers.define :require_review do
  match(&:requires_review?)
end
