require 'spec_helper'

describe ExtraField do
  it "can load all extra fields from configuration files" do
    File.open('./user_fields.rb', 'wb') do |f|
      f.write <<EOS
group 'Grp' do
  field(:name => 'one', :field_type => 'text', :label => 'Field One', :disabled => true)
  field(:name => 'two', :field_type => 'boolean', :default => true)
end
EOS
    end
    ExtraField.stub(:config_files => ['./user_fields.rb'])

    fields = ExtraField.by_kind(:user)
    fields.size.should == 2
    fields[0].group.should == 'Grp'
    fields[0].kind.should == :user
    fields[0].name.should == 'one'
    fields[0].field_type.should == :text
    fields[0].label.should == 'Field One'
    fields[0].options[:disabled].should == true
    fields[0].default.should == nil

    fields[1].group.should == 'Grp'
    fields[1].kind.should == :user
    fields[1].name.should == 'two'
    fields[1].field_type.should == :boolean
    fields[1].label.should == 'two'
    fields[1].default.should == true
  end
end