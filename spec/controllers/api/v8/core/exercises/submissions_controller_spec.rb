# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

describe Api::V8::Core::Exercises::SubmissionsController, type: :controller do
  let(:organization) { FactoryBot.create(:accepted_organization) }
  let(:course) { FactoryBot.create(:course, organization: organization) }
  # returnable_exercise sets returnable_forced, so the exercise accepts submissions without a
  # refreshed course repository behind it -- #create never looks at the exercise's files.
  let(:exercise) { FactoryBot.create(:returnable_exercise, course: course) }
  let(:user) { FactoryBot.create(:verified_user) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  # The controller only inspects the uploaded bytes far enough to see the ZIP magic number
  # ("PK"), so a minimal empty-archive header is enough for the accepted path and any other
  # content for the declined one.
  def upload(contents, filename)
    path = File.join(Dir.mktmpdir, filename)
    File.binwrite(path, contents)
    Rack::Test::UploadedFile.new(path, 'application/octet-stream')
  end

  let(:zip_file) { upload("PK\x05\x06#{"\x00" * 18}", 'submission.zip') }
  let(:text_file) { upload('this is not an archive', 'submission.txt') }

  describe 'Creating a submission' do
    describe 'as an authenticated user' do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      it 'should accept submissions when the deadline is open' do
        exercise.deadline_spec = ['1.1.2100'].to_json
        exercise.save!

        expect { post :create, params: { exercise_id: exercise.id, submission: { file: zip_file } }, format: :json }
          .to change(Submission, :count).by(1)

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

        expect { post :create, params: { exercise_id: exercise.id, submission: { file: zip_file } }, format: :json }
          .not_to change(Submission, :count)

        expect(response).to have_http_status :forbidden
        expect(JSON.parse(response.body)['error']).to eq('Submissions for this exercise are no longer accepted.')
      end

      # A non-ZIP upload is reported in the response body rather than by status code: the client
      # gets 200 with an "error" key and nothing is stored. Asserting the status alone would pass
      # even if the magic-number check were removed, so assert the body and the count too.
      it 'should decline submissions when the file is not ZIP' do
        expect { post :create, params: { exercise_id: exercise.id, submission: { file: text_file } }, format: :json }
          .not_to change(Submission, :count)

        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)['error']).to eq("The uploaded file doesn't look like a ZIP file.")
      end

      it 'should decline submissions when a file is not selected' do
        expect { post :create, params: { exercise_id: exercise.id }, format: :json }
          .not_to change(Submission, :count)

        expect(response).to have_http_status :not_found
        expect(JSON.parse(response.body)['error']).to eq('No ZIP file selected or failed to receive it')
      end
    end

    describe 'as an unauthenticated user' do
      # No Doorkeeper token and no session, so the controller resolves Guest and
      # unauthorize_guest! rejects the request before the exercise is even loaded.
      let(:token) { nil }

      it 'should not allow sending submission' do
        expect { post :create, params: { exercise_id: exercise.id, submission: { file: zip_file } }, format: :json }
          .not_to change(Submission, :count)

        expect(response).to have_http_status :unauthorized
        expect(JSON.parse(response.body)['error']).to eq('Authentication required')
      end
    end
  end
end
