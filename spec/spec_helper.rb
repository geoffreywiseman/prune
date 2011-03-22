RSpec::Matchers.define :include_match do |expected|
  match do |actual|
     !actual.grep( expected ).empty?
  end
end