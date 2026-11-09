# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe Ability, type: :model do
  describe 'a submission whose exercise has been removed from the course' do
    let(:organization) { FactoryBot.create(:accepted_organization) }
    let(:course) { FactoryBot.create(:course, organization: organization) }
    let(:student) { FactoryBot.create(:user) }
    let(:other_student) { FactoryBot.create(:user) }
    let(:teacher) { FactoryBot.create(:user) }
    let(:assistant) { FactoryBot.create(:user) }
    let(:submission) do
      sub = FactoryBot.create(:submission, course: course, user: student)
      sub.exercise.update_column(:name, 'removed-by-refresh')
      Submission.find(sub.id)
    end

    before :each do
      Teachership.create!(user: teacher, organization: organization)
      Assistantship.create!(user: assistant, course: course)
    end

    it 'has no exercise' do
      expect(submission.exercise).to be_nil
    end

    it 'lets the submitter download it and read its results' do
      ability = Ability.new(student)
      expect(ability).to be_able_to(:download, submission)
      expect(ability).to be_able_to(:read_results, submission)
    end

    it 'does not let another student download it' do
      expect(Ability.new(other_student)).not_to be_able_to(:download, submission)
    end

    it 'does not let a guest download it' do
      expect(Ability.new(Guest.new)).not_to be_able_to(:download, submission)
    end

    it 'lets a teacher of the course download it and read its results' do
      ability = Ability.new(teacher)
      expect(ability).to be_able_to(:download, submission)
      expect(ability).to be_able_to(:read_results, submission)
    end

    it 'lets an assistant of the course download it and read its results' do
      ability = Ability.new(assistant)
      expect(ability).to be_able_to(:download, submission)
      expect(ability).to be_able_to(:read_results, submission)
    end

    describe 'on a course that hides submission results' do
      before :each do
        course.update!(hide_submission_results: true)
      end

      it 'hides the results from the submitter' do
        ability = Ability.new(student)
        expect(ability).not_to be_able_to(:download, submission)
        expect(ability).not_to be_able_to(:read_results, submission)
      end

      it 'still shows the results to a teacher and an assistant' do
        expect(Ability.new(teacher)).to be_able_to(:read_results, submission)
        expect(Ability.new(assistant)).to be_able_to(:read_results, submission)
      end
    end
  end
end
