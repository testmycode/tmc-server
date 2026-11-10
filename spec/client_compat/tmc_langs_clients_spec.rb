# typed: false
# frozen_string_literal: true

require 'spec_helper'

# Runs each client's own tmc-langs-cli build against the server, so a response the client
# can't parse fails here instead of in students' editors.
describe 'tmc-langs clients', integration: true do
  include GitTestActions
  include IntegrationTestActions

  let(:root_url) { "#{Capybara.current_session.server.base_url}/" }
  # Organization information and message_for_paste are nullable, but tmc-langs requires strings.
  let(:organization) { FactoryBot.create(:accepted_organization, slug: 'compat', information: nil) }
  let(:teacher) { FactoryBot.create(:verified_user) }
  let(:password) { 'correct horse battery' }
  let(:student) { FactoryBot.create(:verified_user, password: password) }

  before do
    Teachership.create!(user: teacher, organization: organization)
    repo_path = "#{Dir.pwd}/remote_repo"
    create_bare_repo(repo_path)
    @course = FactoryBot.create(:course, name: 'compat-course', organization: organization, source_url: repo_path)
    repo = clone_course_repo(@course)
    repo.copy_simple_exercise('Basic')
    repo.copy_simple_exercise('Locked')
    repo.add_commit_push
    @course.refresh(teacher.id)
    RefreshCourseTask.new.run
    @course.reload

    FactoryBot.create(:course, name: 'compat-hidden', organization: organization, hidden: true)
    @exercise = @course.exercises.find_by!(name: 'Basic')
    @exercise.deadline_spec = ['2099-12-31 23:59'].to_json
    @exercise.soft_deadline_spec = ['2099-06-30 23:59'].to_json
    @exercise.save!
    locked = @course.exercises.find_by!(name: 'Locked')
    locked.unlock_spec = ['exercise Basic'].to_json
    locked.save!
    @question = FactoryBot.create(:feedback_question, course: @course, question: 'How hard was it?')

    zip = FixtureExercise.get('SimpleExercise', "#{Dir.pwd}/web/Basic").tap(&:make_zip).zip_path
    @web_submission = Submission.create!(user: student, course: @course, exercise: @exercise, processed: true,
                                         return_file: File.binread(zip), message_for_paste: nil)
    @reviewed_submission = Submission.create!(user: student, course: @course, exercise: @exercise, processed: true, reviewed: true,
                                  return_file: File.binread(zip))
    Review.create!(submission: @reviewed_submission, reviewer: teacher, review_body: 'Looks good', marked_as_read: false)
  end

  TmcLangsClient.manifest.each do |client|
    context "#{client[:client_name]} #{client[:client_version]} (tmc-langs #{client[:langs_version]})" do
      around do |example|
        Dir.mktmpdir do |dir|
          @langs = TmcLangsClient.new(client, root_url, dir)
          example.run
        end
      end

      def log_in
        @langs.tmc('login', '--base64', '--email', student.email, '--stdin', stdin: Base64.strict_encode64(password), kind: nil)
      end

      def download_exercise(*flags)
        downloaded = @langs.tmc('download-or-update-course-exercises', *flags, '--exercise-id', @exercise.id, kind: 'tmc-exercise-download')['downloaded']
        expect(downloaded.pluck('id')).to eq([@exercise.id])
        downloaded.first['path']
      end

      # Feeds the sandbox result for the submission `run` posted, through the endpoint the sandbox calls.
      def finish_submission(run, known_submission_ids)
        submission = nil
        wait_until(timeout: 30) { submission = Submission.where.not(id: known_submission_ids).first }
        sleep 2.5 # lets the client poll the processing submission a couple of times
        expect(run).to be_running

        submission.update!(secret_token: 'sandbox-token')
        test_output = {
          status: 'PASSED',
          testResults: [{ name: 'SimpleTest testEverything', successful: true, points: @exercise.available_points.map(&:name), message: '', exception: nil }],
          logs: {}
        }
        response = Net::HTTP.post_form(URI("#{root_url}submissions/#{submission.id}/result"),
                                       token: 'sandbox-token', status: 'finished', exit_code: '0', test_output: test_output.to_json)
        expect(response.code).to eq('200')
        submission
      end

      it 'logs in with a password and is refused once the token is revoked' do
        log_in
        expect(@langs.tmc('logged-in', kind: 'token')).to include('access_token', 'token_type')
        expect(File).to exist(@langs.credentials_path)

        Doorkeeper::AccessToken.where(resource_owner_id: student.id).find_each(&:revoke)
        error = @langs.start('get-course-details', '--course-id', @course.id).error
        # tmc-langs 0.39.9 keeps credentials.json after this 401, so the user has to log out before logging in again.
        expect(error['trace'].join).to include('401 Unauthorized')
        @langs.tmc('logout', kind: nil)
        log_in
        expect(@langs.tmc('get-course-details', '--course-id', @course.id, kind: 'course-details')['id']).to eq(@course.id)

        @langs.tmc('logout', kind: nil)
        expect(@langs.tmc('logged-in', kind: nil)).to be_nil
      end

      it 'browses organizations, courses and exercises' do
        log_in
        expect(@langs.tmc('get-organizations', kind: 'organizations').pluck('slug')).to eq(['compat'])
        expect(@langs.tmc('get-organization', '--organization', 'compat', kind: 'organization'))
          .to include('slug' => 'compat', 'logo_path' => 'missing.png')
        expect(@langs.tmc('get-courses', '--organization', 'compat', kind: 'courses').pluck('name')).to eq(['compat-course'])

        details = @langs.tmc('get-course-details', '--course-id', @course.id, kind: 'course-details')
        expect(details['exercises'].pluck('name')).to eq(['Basic'])
        expect(details['exercises'].first).to include('locked' => false, 'checksum' => @exercise.checksum,
                                                      'deadline' => start_with('2099-12-31'), 'soft_deadline' => start_with('2099-06-30'))

        exercises = @langs.tmc('get-course-exercises', '--course-id', @course.id, kind: 'course-exercises')
        expect(exercises.find { |ex| ex['name'] == 'Basic' }['available_points'].pluck('name')).to match_array(@exercise.available_points.map(&:name))
        expect(@langs.tmc('get-course-settings', '--course-id', @course.id, kind: 'course-data')).to include('name' => 'compat-course', 'hidden' => false)
        expect(@langs.tmc('get-course-data', '--course-id', @course.id, kind: 'combined-course-data').keys).to contain_exactly('details', 'exercises', 'settings')

        expect(@langs.tmc('get-exercise-details', '--exercise-id', @exercise.id, kind: 'exercise-details')['exercise_name']).to eq('Basic')
        submissions = @langs.tmc('get-exercise-submissions', '--exercise-id', @exercise.id, kind: 'submissions')
        expect(submissions.pluck('id', 'reviewed')).to contain_exactly([@web_submission.id, false], [@reviewed_submission.id, true])
      end

      it 'downloads, updates and resets exercises' do
        log_in
        exercise_path = download_exercise('--download-template')
        source = File.join(exercise_path, 'src/SimpleStuff.java')
        expect(File).to exist(source)
        redownload = @langs.tmc('download-or-update-course-exercises', '--exercise-id', @exercise.id, kind: 'tmc-exercise-download')
        expect(redownload['skipped'].pluck('id')).to eq([@exercise.id])

        expect(@langs.tmc('check-exercise-updates', kind: 'updated-exercises')).to eq([])
        @exercise.update!(checksum: 'changed-on-the-server')
        expect(@langs.tmc('check-exercise-updates', kind: 'updated-exercises')).to eq([{ 'id' => @exercise.id }])

        saved_states = Submission.where(exercise: @exercise, user: student)
        expect do
          File.write(source, 'edited')
          @langs.tmc('download-old-submission', '--submission-id', @web_submission.id, '--save-old-state',
                     '--exercise-id', @exercise.id, '--output-path', exercise_path, kind: nil)
          expect(File.read(source)).to eq(File.read(File.join(FixtureExercise.fixture_exercises_root, 'SimpleExercise/src/SimpleStuff.java')))

          File.write(source, 'edited again')
          @langs.tmc('reset-exercise', '--save-old-state', '--exercise-id', @exercise.id, '--exercise-path', exercise_path, kind: nil)
          expect(File.read(source)).not_to eq('edited again')
        end.to change(saved_states, :count).by(2)
      end

      it 'submits, waits for the results, sends feedback and pastes' do
        log_in
        exercise_path = download_exercise
        known = Submission.pluck(:id)
        run = @langs.start('submit', '--submission-path', exercise_path, '--exercise-id', @exercise.id)
        submission = finish_submission(run, known)

        result = run.result.dig('data', 'output-data')
        expect(result).to include('status' => 'ok', 'all_tests_passed' => true, 'exercise_name' => 'Basic')
        expect(result['points']).to match_array(@exercise.available_points.map(&:name))
        expect(result['feedback_questions'].pluck('id')).to eq([@question.id])

        @langs.tmc('send-feedback', '--feedback-url', result['feedback_answer_url'], '--feedback', @question.id, 'Not very',
                   kind: 'submission-feedback-response')
        expect(FeedbackAnswer.where(submission: submission).pluck(:answer)).to eq(['Not very'])

        paste = @langs.tmc('paste', '--exercise-id', @exercise.id, '--submission-path', exercise_path, kind: 'new-submission')
        expect(paste['paste_url']).to be_present
      end

      it 'works on an exercise whose results are hidden until the exam ends' do
        @exercise.update!(hide_submission_results: true)
        @web_submission.update!(all_tests_passed: true)
        log_in

        listed = @langs.tmc('get-exercise-submissions', '--exercise-id', @exercise.id, kind: 'submissions').find { |sub| sub['id'] == @web_submission.id }
        expect(listed).to include('all_tests_passed' => false, 'points' => nil)
        details = @langs.tmc('get-exercise-details', '--exercise-id', @exercise.id, kind: 'exercise-details')
        expect(details['submissions'].find { |sub| sub['id'] == @web_submission.id }).to include('all_tests_passed' => false)

        exercise_path = download_exercise
        # The client stops polling as soon as the server says the results are hidden.
        result = @langs.tmc('submit', '--submission-path', exercise_path, '--exercise-id', @exercise.id, kind: 'submission-finished')
        expect(result).to include('status' => 'hidden', 'points' => [])
      end
    end
  end
end
