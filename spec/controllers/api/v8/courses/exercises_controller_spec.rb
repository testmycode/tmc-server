# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::ExercisesController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:course) { FactoryBot.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryBot.create(:exercise, name: 'testexercise', course: course) }
  let!(:hidden_exercise) { FactoryBot.create(:exercise, name: 'hiddentestexercise', course: course, hidden: true) }
  let(:admin) { FactoryBot.create(:admin, password: 'xooxer') }
  let(:user) { FactoryBot.create(:user, login: 'user', password: 'xooxer') }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(200)
      end
      it 'should return the courses exercises' do
        get :index, params: { course_id: course.id }
        expect(response.body).to have_content exercise.name
      end
      it 'should show hidden exercises' do
        get :index, params: { course_id: course.id }
        expect(response.body).to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'when course id is given' do
      it 'should return successful response' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(200)
      end
      it 'should return the courses exercises' do
        get :index, params: { course_id: course.id }
        expect(response.body).to have_content exercise.name
      end
      it 'should not show hidden exercises' do
        get :index, params: { course_id: course.id }
        expect(response.body).not_to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a student without unlock rows' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }

    def unlocked_flags
      get :index, params: { course_id: course.id }
      JSON.parse(response.body).to_h { |ex| [ex['name'], ex['unlocked']] }
    end

    it 'marks a date-unlocked exercise as unlocked once the date has passed' do
      exercise.update!(unlock_spec: ['1.1.2011'].to_json)
      expect(unlocked_flags['testexercise']).to be true
    end

    it 'marks a date-unlocked exercise as locked before the date' do
      exercise.update!(unlock_spec: [(Time.zone.now + 1.day).strftime('%d.%m.%Y %H:%M')].to_json)
      expect(unlocked_flags['testexercise']).to be false
    end
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for exercises' do
      it 'should show authentication error' do
        get :index, params: { course_id: course.id }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course id could not be found' do
      it 'should return error' do
        get :index, params: { course_id: '123' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
