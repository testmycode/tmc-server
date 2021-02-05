# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe 'The system (used by a student)', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create(:user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @course = FactoryBot.create(:course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh(@teacher.id)
    RefreshCourseTask.new.run

    @user = FactoryBot.create(:user, password: 'xooxer')
    @ability = Ability.new(@user)

    log_in_as(@user.login, 'xooxer')
    visit '/org/slug/courses'
    find(:link, 'mycourse').trigger('click')
    # click_link 'mycourse'
  end

  describe 'pastes' do
    it 'By default pastes are publicly visible, if all tests are not passed' do
      skip 'Not working, requires sandbox setup for testing'
      ex = FixtureExercise::SimpleExercise.new('MyExercise')
      ex.make_zip

      click_link 'MyExercise'
      attach_file('Zipped project', 'MyExercise.zip')
      check('Submit to pastebin')
      click_button 'Submit'
      wait_for_submission_to_be_processed

      click_link 'Show Paste'
      expect(page).to have_content('src/SimpleStuff.java')

      log_out

      expect(page).to have_content('src/SimpleStuff.java')
    end

    it 'By default pastes are not publicly visible, if all tests passed' do
      skip 'Not working, requires sandbox setup for testing'
      ex = FixtureExercise::SimpleExercise.new('MyExercise')
      ex.solve_all
      ex.make_zip

      click_link 'MyExercise'
      attach_file('Zipped project', 'MyExercise.zip')
      check('Submit to pastebin')
      click_button 'Submit'
      wait_for_submission_to_be_processed

      expect(page).to have_content('All tests successful')
      expect(page).to have_content('Ok')

      expect(page).not_to have_content 'Show Paste'

      click_link 'Files'

      expect(page).to have_content('src/SimpleStuff.java')

      log_out

      expect(page).not_to have_content('src/SimpleStuff.java')
      expect(page).to have_content('Goodbye')
    end

    it 'when pastes configured as protected, user should not see it unless she has already passed that exercise' do
      skip 'Not working, requires sandbox setup for testing'
      # User1 makes submission getting it marked as done
      # User2 makes failing submission
      # and navigates to paste view
      # User2 logs out
      # and User1 logs in
      # User1 should see the paste
      # User 1 logs out
      # and uset 3 logs in and should not see the paste
      #

      # @course.paste_visibility = 'protected'
      # @course.save
      # ex = FixtureExercise::SimpleExercise.new('MyExercise')
      # ex.solve_all
      # ex.make_zip

      # click_link 'MyExercise'
      # attach_file('Zipped project', 'MyExercise.zip')
      # click_button 'Submit'
      # wait_for_submission_to_be_processed
      # expect(page).to have_content('All tests successful')
      # expect(page).to have_content('Ok')

      # visit '/org/slug/courses'

      # log_out

      # @other_user = FactoryBot.create(:user, login: 'uuseri', password: 'xooxer')

      # log_in_as(@other_user.login, 'xooxer')

      # ex = FixtureExercise::SimpleExercise.new('MyExercise')
      # ex.make_zip

      # click_link 'mycourse'
      # first('.exercise-list').click_link 'MyExercise'
      # attach_file('Zipped project', 'MyExercise.zip')
      # check('Submit to pastebin')
      # click_button 'Submit'
      # wait_for_submission_to_be_processed

      # click_link 'Show Paste'
      # expect(page).to have_content('src/SimpleStuff.java')

      # log_out

      # log_in_as(@user.login, 'xooxer')

      # expect(page).to have_content('src/SimpleStuff.java')

      # log_out
      # @other_user = FactoryBot.create(:user, login: 'uuseri2', password: 'xooxer2')
      # log_in_as(@other_user.login, 'xooxer2')

      # expect(page).not_to have_content('src/SimpleStuff.java')
      # expect(page).to have_content('Access denied')

      # log_out

      # expect(page).not_to have_content('src/SimpleStuff.java')
      # expect(page).to have_content('Access denied')
    end

    it 'when pastes configured as protected, user should never see paste if all tests passed' do
      skip 'Not working, requires sandbox setup for testing'
      # User1 makes submission getting it marked as done
      # User2 makes also a passing submission
      # and navigates to paste view
      # User2 logs out
      # and User1 logs in
      # User1 should not see the paste
      # User 1 logs out
      # and uset 3 logs in and should not see the paste

      @course.paste_visibility = 'protected'
      @course.save
      ex = FixtureExercise::SimpleExercise.new('MyExercise')
      ex.solve_all
      ex.make_zip

      puts 'Step 1'

      click_link 'MyExercise'
      attach_file('Zipped project', 'MyExercise.zip')
      click_button 'Submit'
      wait_for_submission_to_be_processed
      expect(page).to have_content('All tests successful')
      expect(page).to have_content('Ok')

      visit '/org/slug/courses'

      log_out
      puts 'Step 2'

      @other_user = FactoryBot.create(:user, login: 'uuseri', password: 'xooxer')

      log_in_as(@other_user.login, 'xooxer')

      ex = FixtureExercise::SimpleExercise.new('MyExercise')
      ex.solve_all
      ex.make_zip
      puts 'Step 3'

      click_link 'mycourse'
      first('.exercise-list').click_link 'MyExercise'
      attach_file('Zipped project', 'MyExercise.zip')
      check('Submit to pastebin')
      click_button 'Submit'
      wait_for_submission_to_be_processed

      puts 'Step 4'
      expect(page).not_to have_content 'Show Paste'

      puts 'Step 5'
      key = Submission.last.paste_key
      visit "/paste/#{key}"

      puts 'Step 6'
      expect(page).to have_content('src/SimpleStuff.java')
      expect(page).not_to have_content('Access denied')

      puts 'Step 7'
      log_out

      log_in_as(@user.login, 'xooxer')

      puts 'Step 8'
      expect(page).not_to have_content('src/SimpleStuff.java')
      expect(page).to have_content('Access denied')

      puts 'Step 9'
      log_out
      @other_user = FactoryBot.create(:user, login: 'uuseri2', password: 'xooxer2')
      log_in_as(@other_user.login, 'xooxer2')

      puts 'Step 10'
      expect(page).not_to have_content('src/SimpleStuff.java')
      expect(page).to have_content('Access denied')

      log_out

      puts 'Step 11'

      expect(page).not_to have_content('src/SimpleStuff.java')
      expect(page).to have_content('Access denied')
      puts 'Step 12'
    end
  end
end
