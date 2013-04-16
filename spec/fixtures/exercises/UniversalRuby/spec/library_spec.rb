require 'rspec'
require_relative '../lib/library.rb'

describe Library do
  subject { Library.new }

  its(:hello_world) { should == "Hello world!" }
  its(:returns_zero) { should == 0 }
  its(:returns_zero) { should == 1 }

end
__END__
1.1
1.2
1.3