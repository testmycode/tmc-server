RSpec::Matchers.define :require_review do
  match do |actual|
    actual.requires_review?
  end
end
