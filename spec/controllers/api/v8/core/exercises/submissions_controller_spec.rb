# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Exercises::SubmissionsController, type: :controller do
  let(:organization) { FactoryBot.create(:accepted_organization) }
  let(:course) { FactoryBot.create(:course, organization: organization) }
  # returnable_forced lets the exercise accept submissions without a refreshed course repository;
  # #create never reads its files.
  let(:exercise) { FactoryBot.create(:returnable_exercise, course: course) }
  let(:user) { FactoryBot.create(:verified_user) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  def upload(name)
    Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/submission_uploads', name), 'application/octet-stream')
  end

  def create_submission(file)
    params = { exercise_id: exercise.id }
    params[:submission] = { file: file } if file
    post :create, params: params, format: :json
  end

  let(:zip_file) { upload('empty.zip') }
  let(:text_file) { upload('not_a_zip.txt') }

  describe 'Creating a submission' do
    describe 'as an authenticated user' do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      it 'should accept submissions when the deadline is open' do
        exercise.deadline_spec = ['1.1.2100'].to_json
        exercise.save!

        expect { create_submission(zip_file) }.to change(Submission, :count).by(1)

        expect(response).to have_http_status :ok
        json = JSON.parse(response.body)
        expect(json).not_to have_key('error')

        submission = Submission.last
        expect(json['submission_url']).to end_with("/api/v8/core/submissions/#{submission.id}")
        expect(submission.user).to eq(user)
        expect(submission.exercise_name).to eq(exercise.name)
        expect(submission.course).to eq(course)
      end

      it 'should decline submissions when the deadline is closed' do
        exercise.deadline_spec = ['1.1.2000'].to_json
        exercise.save!

        expect { create_submission(zip_file) }.not_to change(Submission, :count)

        expect(response).to have_http_status :forbidden
        expect(JSON.parse(response.body)['error']).to eq('Submissions for this exercise are no longer accepted.')
      end

      # Refused in the body only; the status stays 200.
      it 'should decline submissions when the file is not ZIP' do
        expect { create_submission(text_file) }.not_to change(Submission, :count)

        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)['error']).to eq("The uploaded file doesn't look like a ZIP file.")
      end

      it 'should decline submissions when a file is not selected' do
        expect { create_submission(nil) }.not_to change(Submission, :count)

        expect(response).to have_http_status :not_found
        expect(JSON.parse(response.body)['error']).to eq('No ZIP file selected or failed to receive it')
      end
    end

    describe 'as an unauthenticated user' do
      let(:token) { nil }

      it 'should not allow sending submission' do
        expect { create_submission(zip_file) }.not_to change(Submission, :count)

        expect(response).to have_http_status :unauthorized
        expect(JSON.parse(response.body)['error']).to eq('Authentication required')
      end
    end
  end
end
