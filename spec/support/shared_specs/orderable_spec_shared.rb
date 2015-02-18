require 'spec_helper'

shared_examples_for 'an Orderable' do
  # requires a context with a method `new_record` defined to make a new record that's otherwise valid but missing a position

  let(:some_existing_records) do
    records = (1..10).map { new_record }
    records.each(&:save!)
    records
  end

  it 'should default a nil position to the end of the list' do
    first = new_record
    third = new_record
    second = new_record
    first.save!
    second.save!
    third.save!

    expect(first.position).to be < second.position
    expect(second.position).to be < third.position
  end

  it 'should validate uniqueness of position' do
    first = new_record
    first.save!
    second = new_record
    second.position = first.position
    expect(second).not_to be_valid
    expect(second.errors[:position].size).to eq(1)
  end

  describe '#move_forward!' do
    it 'should move the record after the next record' do
      records = some_existing_records
      records[7].move_forward!
      records.each(&:reload)

      expect(records[7].position).to be > records[8].position
      expect(records[7].position).to be < records[9].position

      records.delete_at(7)
      positions = records.map(&:position)
      expect(positions).to eq(positions.sort)
    end

    context 'when there is no next record' do
      it 'should do nothing' do
        records = some_existing_records
        position_before = records.last.position

        records.last.move_forward!

        records.last.reload
        expect(records.last.position).to eq(position_before)
      end
    end
  end

  describe '#move_backward!' do
    it 'should move the record before the previous record' do
      records = some_existing_records
      records[7].move_backward!
      records.each(&:reload)

      expect(records[7].position).to be < records[6].position
      expect(records[7].position).to be > records[5].position

      records.delete_at(7)
      positions = records.map(&:position)
      expect(positions).to eq(positions.sort)
    end

    context 'when there is no previous record' do
      it 'should do nothing' do
        records = some_existing_records
        position_before = records.first.position

        records.first.move_backward!

        records.first.reload
        expect(records.first.position).to eq(position_before)
      end
    end
  end

  describe '#move_before!' do
    it 'should move the record before another record' do
      records = some_existing_records
      records[7].move_before!(records[3])
      records.each(&:reload)
      records[1].move_before!(records[3])
      records.each(&:reload)

      expect(records[7].position).to be < records[1].position
      expect(records[1].position).to be < records[3].position
    end
  end

  describe '#move_after!' do
    it 'should move the record before another record' do
      records = some_existing_records
      records[7].move_after!(records[3])
      records.each(&:reload)
      records[1].move_after!(records[3])
      records.each(&:reload)

      expect(records[7].position).to be > records[1].position
      expect(records[1].position).to be > records[3].position
    end
  end
end
