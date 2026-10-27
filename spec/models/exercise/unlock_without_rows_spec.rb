# frozen_string_literal: true

require 'spec_helper'

describe Exercise, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'date-only unlock for a user without unlock rows' do
    let(:course) { FactoryBot.create(:course) }
    let(:user) { FactoryBot.create(:user) }
    let(:exercise) { FactoryBot.create(:returnable_exercise, course: course, name: 'week1-01_first') }

    def unlock_spec_of(*conditions)
      exercise.unlock_spec = conditions.to_json
      exercise.save!
    end

    before :each do
      expect(Unlock.where(user_id: user.id)).to be_empty
      expect(UncomputedUnlock.where(user_id: user.id)).to be_empty
    end

    it 'is unlocked, visible, downloadable and submittable after the date' do
      unlock_spec_of((Time.zone.now - 1.day).strftime('%d.%m.%Y %H:%M'))

      expect(exercise).to be_unlocked_for(user)
      expect(exercise.visible_to?(user)).to be true
      expect(exercise.downloadable_by?(user)).to be true
      expect(exercise.submittable_by?(user)).to be true
    end

    it 'is locked before the date' do
      unlock_spec_of((Time.zone.now + 1.day).strftime('%d.%m.%Y %H:%M'))

      expect(exercise).not_to be_unlocked_for(user)
      expect(exercise.submittable_by?(user)).to be false
      expect(exercise.downloadable_by?(user)).to be false
    end

    it 'unlocks exactly at the Helsinki wall-clock time' do
      unlock_spec_of('26.10.2026 12:00')

      travel_to Time.utc(2026, 10, 26, 9, 59, 59) do
        expect(exercise).not_to be_unlocked_for(user)
      end
      travel_to Time.utc(2026, 10, 26, 10, 0, 0) do
        expect(exercise).to be_unlocked_for(user)
      end
    end

    it 'does not create unlock rows while evaluating' do
      unlock_spec_of('1.1.2011')

      expect(exercise).to be_unlocked_for(user)
      expect(Unlock.count).to eq(0)
    end

    it 'reports the unlock date as the unlock time' do
      unlock_spec_of('1.1.2011')

      expect(exercise.time_unlocked_for(user)).to eq(Time.zone.parse('2011-01-01'))
    end

    it 'ignores a stale row for a date that moved into the future' do
      unlock_spec_of((Time.zone.now + 1.day).strftime('%d.%m.%Y %H:%M'))
      Unlock.create!(user: user, course: course, exercise_name: exercise.name, valid_after: Time.zone.now - 1.day)

      expect(exercise).not_to be_unlocked_for(user)
    end

    it 'stays locked for a progress-based condition without a row' do
      other = FactoryBot.create(:exercise, course: course, name: 'week0-01_other')
      AvailablePoint.create!(exercise_id: other.id, name: 'ap1')
      unlock_spec_of('1.1.2011', 'exercise week0')

      expect(exercise).not_to be_unlocked_for(user)
    end

    it 'stays locked for an explicit-unlock exercise without a row and creates none' do
      exercise.deadline_spec = ['unlock + 5 days'].to_json
      unlock_spec_of('1.1.2011')
      exercise.reload
      expect(exercise.requires_explicit_unlock?).to be true

      expect(exercise).not_to be_unlocked_for(user)
      expect(exercise.submittable_by?(user)).to be false
      expect(Unlock.count).to eq(0)
    end
  end
end
