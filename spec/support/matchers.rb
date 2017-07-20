RSpec::Matchers.define :be_boolean do
  match do |actual|
    expect(actual.is_a?(TrueClass) || actual.is_a?(FalseClass)).to be true
  end
end
