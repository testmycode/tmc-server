require 'spec_helper'

describe ExtraField, type: :model do

  def use_config(config_text)
    File.open('./user_fields.rb', 'wb') do |f|
      f.write config_text
    end
    allow(ExtraField).to receive_messages(config_files: ['./user_fields.rb'])
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
    @user = FactoryGirl.create(:user)
  end

  after :each do
    UserField.instance_variable_set('@all', nil)
    ExtraField.instance_variable_set('@fields', nil)
  end

  it "can load all extra fields from configuration files" do
    use_default_config

    fields = ExtraField.by_kind(:user)
    expect(fields.size).to eq(2)
    expect(fields[0].group).to eq('Grp')
    expect(fields[0].kind).to eq(:user)
    expect(fields[0].name).to eq('one')
    expect(fields[0].field_type).to eq(:text)
    expect(fields[0].label).to eq('Field One')

    expect(fields[1].group).to eq('Grp')
    expect(fields[1].kind).to eq(:user)
    expect(fields[1].name).to eq('two')
    expect(fields[1].field_type).to eq(:boolean)
    expect(fields[1].label).to eq('two')
  end

  describe "values" do
    it "can be saved" do
      use_default_config

      field = ExtraField.by_kind(:user)[0]
      rec = @user.field_value_record(field)
      expect(rec).not_to be_nil
      rec.value = 'asdasd'
      rec.save!
      expect(@user.reload.field_value_record(field).value).to eq('asdasd')
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

      expect(@user.reload.field_value_record(textfield).value).to eq('foo')
      expect(@user.reload.field_value_record(boolfield).value).to eq('1')
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

      expect(@user.reload.field_value_record(textfield).value).to be_blank
      expect(@user.reload.field_value_record(boolfield).value).to be_blank
    end

    context "of boolean fields" do
      it "take a blank form value to mean false" do
        use_default_config
        boolfield = ExtraField.by_kind(:user)[1]
        boolrec = @user.field_value_record(boolfield)
        boolrec.set_from_form('1')
        boolrec.set_from_form(nil)
        boolrec.save!
        expect(@user.reload.field_value_record(boolfield).value).to be_blank
      end
    end
  end
end
