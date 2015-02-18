require 'spec_helper'

describe DeadlineSpec, type: :model do
  let(:ex) { mock_model(Exercise) }
  let(:user) { mock_model(User) }

  specify 'deadline: <date>' do
    spec = DeadlineSpec.new(ex, ['10.10.2010'])
    expect(spec.deadline_for(user)).to eq(Date.parse('2010-10-10').end_of_day)
  end

  specify 'deadline: <time>' do
    spec = DeadlineSpec.new(ex, ['10.10.2010 10:30'])
    expect(spec.deadline_for(user)).to eq(Time.zone.parse('2010-10-10 10:30'))
  end

  specify 'deadline: unlock + <n> <unit_of_time>' do
    unlock_time = Time.zone.parse('2011-11-11 11:11')
    allow(ex).to receive(:time_unlocked_for).with(user).and_return(unlock_time)
    spec = DeadlineSpec.new(ex, ['unlock + 3 weeks'])
    expect(spec.deadline_for(user)).to eq(unlock_time + 3.weeks)
  end

  describe 'deadline: <multiple deadlines>' do
    it 'should pick the earliest one' do
      unlock_time = Time.zone.parse('2010-10-10 10:00')
      allow(ex).to receive(:time_unlocked_for).with(user).and_return(unlock_time)

      spec = DeadlineSpec.new(ex, ['unlock + 1 day', '2010-10-10 11:11'])
      expect(spec.deadline_for(user)).to eq(Time.zone.parse('2010-10-10 11:11'))

      spec = DeadlineSpec.new(ex, ['unlock + 1 day', '2010-10-13 11:11'])
      expect(spec.deadline_for(user)).to eq(Time.zone.parse('2010-10-11 10:00'))
    end
  end
end
