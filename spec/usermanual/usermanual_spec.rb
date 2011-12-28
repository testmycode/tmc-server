require 'spec_helper'

describe "User manual", :type => :request, :usermanual => true, :integration => true do
  it "has a page for instructors" do
    doc = DocGen.new("instructors", self)
    doc.render_template(File.join(File.dirname(__FILE__), "instructors.html.erb"))
  end
end

