require 'spec_helper'

describe ExtraField do

  def use_config(config_text)
    File.open('./user_fields.rb', 'wb') do |f|
      f.write config_text
    end
    ExtraField.stub(:config_files => ['./user_fields.rb'])
  end

  def use_default_config
    use_config <<EOS
group 'Grp' do
  field(:name => 'one', :field_type => 'text', :label => 'Field One')
  field(:name => 'two', :field_type => 'boolean')
end
EOS
  end

  before :each do
    @user = Factory.create(:user)
  end

  after :each do
    UserField.instance_variable_set('@all', nil)
    ExtraField.instance_variable_set('@fields', nil)
  end

  it "can load all extra fields from configuration files" do
    use_default_config

    fields = ExtraField.by_kind(:user)
    fields.size.should == 2
    fields[0].group.should == 'Grp'
    fields[0].kind.should == :user
    fields[0].name.should == 'one'
    fields[0].field_type.should == :text
    fields[0].label.should == 'Field One'

    fields[1].group.should == 'Grp'
    fields[1].kind.should == :user
    fields[1].name.should == 'two'
    fields[1].field_type.should == :boolean
    fields[1].label.should == 'two'
  end

  describe "values" do
    it "can be saved" do
      use_default_config

      field = ExtraField.by_kind(:user)[0]
      rec = @user.field_value_record(field)
      rec.should_not be_nil
      rec.value = 'asdasd'
      rec.save!
      @user.reload.field_value_record(field).value.should == 'asdasd'
    end

    it "can take their values from forms" do
      use_default_config

      textfield = ExtraField.by_kind(:user)[0]
      boolfield = ExtraField.by_kind(:user)[1]

      textrec = @user.field_value_record(textfield)
      boolrec = @user.field_value_record(boolfield)

      textrec.set_from_form('foo')
      textrec.save!

      boolrec.set_from_form('1')
      boolrec.save!

      @user.reload.field_value_record(textfield).value.should == 'foo'
      @user.reload.field_value_record(boolfield).value.should == '1'
    end

    it "won't take their values from forms if disabled or hidden" do
      use_config <<EOS
group 'Grp' do
  field(:name => 'one', :field_type => 'text', :disabled => true)
  field(:name => 'two', :field_type => 'boolean', :hidden => true)
end
EOS

      textfield = ExtraField.by_kind(:user)[0]
      boolfield = ExtraField.by_kind(:user)[1]

      textrec = @user.field_value_record(textfield)
      boolrec = @user.field_value_record(boolfield)

      textrec.set_from_form('this should not actually be set')
      textrec.save!

      boolrec.set_from_form('1')
      boolrec.save!

      @user.reload.field_value_record(textfield).value.should be_blank
      @user.reload.field_value_record(boolfield).value.should be_blank
    end

    context "of boolean fields" do
      it "take a blank form value to mean false" do
        use_default_config
        boolfield = ExtraField.by_kind(:user)[1]
        boolrec = @user.field_value_record(boolfield)
        boolrec.set_from_form('1')
        boolrec.set_from_form(nil)
        boolrec.save!
        @user.reload.field_value_record(boolfield).value.should be_blank
      end
    end
  end
end