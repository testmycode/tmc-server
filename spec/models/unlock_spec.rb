# frozen_string_literal: true

require 'spec_helper'

describe Unlock, type: :model do
  describe '#refresh_unlocks' do
    before :each do
      @course = FactoryBot.create(:course)
      @ex1 = FactoryBot.create(:exercise, course: @course, name: 'ex1')
      @ex2 = FactoryBot.create(:exercise, course: @course, name: 'ex2')
      @ex1.unlock_spec = ['11.11.2011'].to_json
      @ex2.unlock_spec = ['2011-11-22', 'exercise ex1'].to_json
      @ex1.save!
      @ex2.save!

      @user = FactoryBot.create(:user)
      @available_point = FactoryBot.create(:available_point, exercise_id: @ex1.id)
      @available_point2 = FactoryBot.create(:available_point, exercise_id: @ex2.id)

      @submission = FactoryBot.create(:submission, course: @course, user: @user, exercise: @ex1)

      @course.reload
    end

    it 'creates unlocks as specified' do
      Unlock.refresh_unlocks(@course, @user)
      unlocks = Unlock.order('exercise_name ASC').to_a
      expect(unlocks.size).to eq(1)

      expect(unlocks.first.valid_after).to eq(Date.parse('2011-11-11').in_time_zone)
      expect(unlocks.first.exercise_name).to eq('ex1')

      AwardedPoint.create!(user_id: @user.id, course_id: @course.id, name: @available_point.name, submission_id: @submission.id)
      Unlock.refresh_unlocks(@course, @user)

      unlocks = Unlock.order('exercise_name ASC').to_a
      expect(unlocks.size).to eq(2)

      expect(unlocks.second.valid_after).to eq(Date.parse('2011-11-22').in_time_zone)
      expect(unlocks.second.exercise_name).to eq('ex2')
    end

    it "doesn't recreate old unlocks" do
      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(exercise_name: 'ex1').first
      id = u.id
      created_at = u.created_at

      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(exercise_name: 'ex1').first
      expect(u.id).to eq(id)
      expect(u.created_at).to eq(created_at)
    end
  end
end
