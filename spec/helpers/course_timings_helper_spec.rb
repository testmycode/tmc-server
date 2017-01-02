require 'spec_helper'

describe CourseTimingsHelper, type: :helper do
  describe 'integer parsing' do
    it 'should parse integer right' do
      condition = '72% from Module_4'
      expect(parse_percentage_from_unlock_condition(condition)).to be(72)
    end

    it 'should return nil for other condition types' do
      expect(parse_percentage_from_unlock_condition('')).to be(nil)
      expect(parse_percentage_from_unlock_condition('12 exercises from Module_4')).to be(nil)
      expect(parse_percentage_from_unlock_condition('12 Module_4')).to be(nil)
      expect(parse_percentage_from_unlock_condition('14.7.2014')).to be(nil)
    end
  end

  describe 'group parsing' do
    it 'should return correct group' do
      expect(parse_group_from_unlock_condition('72% from Module_4')).to eq('Module_4')
    end

    it 'should return nil for other condition types' do
      expect(parse_group_from_unlock_condition('')).to eq(nil)
      expect(parse_group_from_unlock_condition('12 from Module_4')).to eq(nil)
      expect(parse_group_from_unlock_condition('12 Module_4')).to eq(nil)
      expect(parse_group_from_unlock_condition('14.7.2014')).to eq(nil)
    end
  end

  describe 'complex condition check' do
    before(:each) do
      @course = FactoryGirl.create :course, name: 'test-course-1', title: 'Test Course 1'
      @ex1 = FactoryGirl.create :exercise, name: 'Module_1-ex1', course: @course
      @ex2 = FactoryGirl.create :exercise, name: 'Module_1-ex2', course: @course
      @ex3 = FactoryGirl.create :exercise, name: 'Module_2-ex2', course: @course
      @group = @course.exercise_group_by_name('Module_1')
    end

    it 'should return false for simple cases' do
      @group.group_unlock_conditions = [].to_json
      expect(complex_unlock_conditions?(@group)).to eq(false)
      @group.group_unlock_conditions = [''].to_json
      expect(complex_unlock_conditions?(@group)).to eq(false)
      @group.group_unlock_conditions = ['91% from Module_2'].to_json
      expect(complex_unlock_conditions?(@group)).to eq(false)
    end

    it 'should return true for complex cases' do
      @group.group_unlock_conditions = ['12 exercises from Module_2'].to_json
      expect(complex_unlock_conditions?(@group)).to eq(true)
      @group.group_unlock_conditions = ['14.7.2014'].to_json
      expect(complex_unlock_conditions?(@group)).to eq(true)
      @group.group_unlock_conditions = ['91% from Module_2', '14.7.2014'].to_json
      expect(complex_unlock_conditions?(@group)).to eq(true)
    end
  end
end
