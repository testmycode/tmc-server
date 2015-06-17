require 'spec_helper'

describe Course, type: :model do
  let(:source_path) { "#{@test_tmp_dir}/fake_source" }
  let(:source_url) { "file://#{source_path}" }
  let(:user) { FactoryGirl.create(:user) }

  describe 'gdocs_sheets' do
    it 'should list all unique gdocs_sheets of a course' do
      course = FactoryGirl.create(:course)
      ex1 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: 'sheet1')
      ex2 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: 'sheet1')
      ex3 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: 'sheet2')
      ex4 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: nil)
      worksheets = course.gdocs_sheets

      expect(worksheets.size).to eq(2)
      expect(worksheets).to include('sheet1')
      expect(worksheets).to include('sheet2')
      expect(worksheets).not_to include(nil)
    end
  end

  describe 'paths used' do
    it 'should be absolute' do
      class_paths = [
        :cache_root
      ]
      for path in class_paths
        expect(Course.send(path)).to match(/^\//)
      end

      object_paths = [
        :cache_path,
        :stub_zip_path,
        :solution_zip_path,
        :clone_path
      ]

      for path in object_paths
        expect(Course.new.send(path)).to match(/^\//)
      end
    end
  end

  it 'should be visible if not hidden and hide_after is nil' do
    c = FactoryGirl.create(:course, hidden: false, hide_after: nil)
    expect(c).to be_visible_to(user)
  end

  it 'should be visible if not hidden and hide_after has not passed' do
    c = FactoryGirl.create(:course, hidden: false, hide_after: Time.now + 2.minutes)
    expect(c).to be_visible_to(user)
  end

  it 'should not be visible if hidden' do
    c = FactoryGirl.create(:course, hidden: true, hide_after: nil)
    expect(c).not_to be_visible_to(user)
  end

  it 'should not be visible if hide_after has passed' do
    c = FactoryGirl.create(:course, hidden: false, hide_after: Time.now - 2.minutes)
    expect(c).not_to be_visible_to(user)
  end

  it 'should always be visible to administrators' do
    admin = FactoryGirl.create(:admin)
    c = FactoryGirl.create(:course, hidden: true, hide_after: Time.now - 2.minutes)
    expect(c).to be_visible_to(admin)
  end

  it 'should always be visible to organization teachers' do
    organization = FactoryGirl.create(:accepted_organization)
    Teachership.create!(user: user, organization: organization)
    c = FactoryGirl.create(:course, hidden: true, hide_after: Time.now - 2.minutes, organization: organization)
    expect(c).to be_visible_to(user)
  end

  it 'should be visible if user has registered before the hidden_if_registered_after setting' do
    user.created_at = Time.zone.parse('2010-01-02')
    user.save!
    c = FactoryGirl.create(:course, hidden_if_registered_after: Time.zone.parse('2010-01-03'))
    expect(c).to be_visible_to(user)
  end

  it 'should not be visible if user has registered after the hidden_if_registered_after setting' do
    user.created_at = Time.zone.parse('2010-01-02')
    user.save!
    c = FactoryGirl.create(:course, hidden_if_registered_after: Time.zone.parse('2010-01-01'))
    expect(c).not_to be_visible_to(user)
  end

  it 'should accept Finnish dates and datetimes for hide_after' do
    c = FactoryGirl.create(:course)
    c.hide_after = '19.8.2012'
    expect(c.hide_after.day).to eq(19)
    expect(c.hide_after.month).to eq(8)
    expect(c.hide_after.year).to eq(2012)

    c.hide_after = '15.9.2011 19:15'
    expect(c.hide_after.day).to eq(15)
    expect(c.hide_after.month).to eq(9)
    expect(c.hide_after.hour).to eq(19)
    expect(c.hide_after.year).to eq(2011)
  end

  it 'should consider a hide_after date without time to mean the end of that day' do
    c = FactoryGirl.create(:course, hide_after: '18.11.2013')
    expect(c.hide_after.hour).to eq(23)
    expect(c.hide_after.min).to eq(59)
  end

  it 'should know the exercise groups of its exercises' do
    c = FactoryGirl.create(:course)
    exercises = [
      FactoryGirl.build(:exercise, course: c, name: 'foo-ex1'),
      FactoryGirl.build(:exercise, course: c, name: 'bar-ex1'),
      FactoryGirl.build(:exercise, course: c, name: 'foo-ex2'),
      FactoryGirl.build(:exercise, course: c, name: 'zoox-zaax-ex1'),
      FactoryGirl.build(:exercise, course: c, name: 'zoox-zoox-ex1')
    ]
    exercises.each { |ex| c.exercises << ex }

    # They should be sorted
    expect(c.exercise_groups.size).to eq(5)
    expect(c.exercise_groups[0].name).to eq('bar')
    expect(c.exercise_groups[1].name).to eq('foo')
    expect(c.exercise_groups[2].name).to eq('zoox')
    expect(c.exercise_groups[3].name).to eq('zoox-zaax')
    expect(c.exercise_groups[4].name).to eq('zoox-zoox')

    expect(c.exercise_group_by_name('zoox-zaax').parent).to eq(c.exercise_group_by_name('zoox'))
    expect(c.exercise_group_by_name('zoox').children.size).to eq(2)
    expect(c.exercise_group_by_name('zoox').children[0]).to eq(c.exercise_group_by_name('zoox-zaax'))
    expect(c.exercise_group_by_name('zoox').children[1]).to eq(c.exercise_group_by_name('zoox-zoox'))

    expect(c.exercises_by_name_or_group('zoox-zaax')).to eq([exercises[3]])
    expect(c.exercises_by_name_or_group('zoox-zaax-ex1')).to eq([exercises[3]])
    expect(c.exercises_by_name_or_group('zoox-zaa')).to eq([])
    expect(c.exercises_by_name_or_group('foo').natsort_by(&:name)).to eq([exercises[0], exercises[2]])
    expect(c.exercises_by_name_or_group('asdasd')).to eq([])
  end

  describe 'validation' do
    let(:valid_params) do
      {
        name: 'TestCourse',
        title: 'Test Course',
        source_url: 'git@example.com'
      }
    end

    it 'requires a name' do
      should_be_invalid_params(valid_params.merge(name: nil))
    end

    it 'requires name to be reasonably short' do
      should_be_invalid_params(valid_params.merge(name: 'a' * 41))
    end

    it 'requires name to be non-unique' do
      organization = FactoryGirl.create :accepted_organization
      Course.create!(valid_params.merge(organization: organization))
      should_be_invalid_params(valid_params.merge(organization: organization))
    end

    it 'allows same course name in different organizations' do
      organization1 = FactoryGirl.create :accepted_organization
      organization2 = FactoryGirl.create :accepted_organization
      Course.create!(valid_params.merge(organization: organization1))
      expect{ Course.create!(valid_params.merge(organization: organization2)) }.not_to raise_error
    end

    it 'forbids spaces in the name' do # this could eventually be lifted as long as everything else is made to tolerate spaces
      should_be_invalid_params(valid_params.merge(name: 'Test Course'))
    end

    it 'requires a title' do
      should_be_invalid_params(valid_params.merge(title: nil))
      should_be_invalid_params(valid_params.merge(title: ''))
    end

    it 'requires title to be reasonably short' do
      should_be_invalid_params(valid_params.merge(title: 'a' * 41))
    end

    it 'requires a remote repo url' do
      should_be_invalid_params(valid_params.merge(source_url: nil))
      should_be_invalid_params(valid_params.merge(source_url: ''))
    end

    def should_be_invalid_params(params)
      expect { Course.create!(params) }.to raise_error
    end
  end

  describe 'destruction' do
    it 'deletes its cache directory' do
      c = Course.create!(name: 'MyCourse', title: 'My Course', source_url: source_url)
      FileUtils.mkdir_p(c.cache_path)
      FileUtils.touch("#{c.cache_path}/foo.txt")

      c.destroy
      expect(File).not_to exist(c.cache_path)
    end

    it 'deletes dependent exercises' do
      ex = FactoryGirl.create(:exercise)
      ex.course.destroy
      assert_destroyed(ex)
    end

    it 'deletes dependent submissions' do
      sub = FactoryGirl.create(:submission)
      sub.course.destroy
      assert_destroyed(sub)
    end

    it 'deletes dependent feedback questions and answers' do
      a = FactoryGirl.create(:feedback_answer)
      q = a.feedback_question
      q.course.destroy
      assert_destroyed(a)
      assert_destroyed(q)
    end

    it 'deletes available points' do
      pt = FactoryGirl.create(:available_point)
      pt.course.destroy
      assert_destroyed(pt)
    end

    it 'deletes awarded points' do
      pt = FactoryGirl.create(:awarded_point)
      pt.course.destroy
      assert_destroyed(pt)
    end

    it 'deletes test scanner cache entries' do
      ent = FactoryGirl.create(:test_scanner_cache_entry)
      ent.course.destroy
      assert_destroyed(ent)
    end

    def assert_destroyed(obj)
      expect(obj.class.find_by_id(obj.id)).to be_nil
    end
  end

  describe 'contains_unlock_deadlines?' do
    before :each do
      @course = FactoryGirl.create(:course)
      @ex1 = FactoryGirl.create(:exercise, course: @course)
      @ex2 = FactoryGirl.create(:exercise, course: @course)
      @ex3 = FactoryGirl.create(:exercise, course: @course)
    end

    it 'returns false if no exercise in the course has unlock-based deadlines' do
      @ex1.deadline_spec = ['2.2.2000'].to_json
      @ex2.deadline_spec = ['3.2.2000'].to_json
      @ex1.soft_deadline_spec = ['1.2.2000'].to_json
      @ex3.soft_deadline_spec = ['1.1.2000'].to_json

      [@ex1, @ex2, @ex3].each { |e| e.save! }

      expect(@course.contains_unlock_deadlines?).to eq(false)
    end

    it 'returns true if any exercise in the course has unlock-based deadlines' do
      @ex1.deadline_spec = ['2.2.2000'].to_json
      @ex2.deadline_spec = ['3.2.2000'].to_json
      @ex1.soft_deadline_spec = ['1.2.2000', 'unlock + 5 days'].to_json
      @ex3.soft_deadline_spec = ['1.1.2000'].to_json

      [@ex1, @ex2, @ex3].each { |e| e.save! }

      expect(@course.contains_unlock_deadlines?).to eq(true)
    end

    it 'assigns material_url with http:// prepended to it' do
      course = FactoryGirl.create :course, material_url: 'google.com'
      expect(course.material_url).to eq('http://google.com')
      course.material_url = ''
      expect(course.material_url).to eq('')
      course.material_url = 'https://google.com'
      expect(course.material_url).to eq('https://google.com')
      course.material_url = 'http://google.com'
      expect(course.material_url).to eq('http://google.com')
    end
  end
end
