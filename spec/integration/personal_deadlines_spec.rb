require 'spec_helper'

describe 'Personal deadlines', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create(:user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @course = FactoryGirl.create(:course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise1')
    @repo.copy_simple_exercise('MyExercise2')
    File.open("#{@repo.path}/MyExercise2/metadata.yml", 'wb') do |f|
      f.puts('unlocked_after: exercise MyExercise1')
    end
    @repo.add_commit_push

    @user = FactoryGirl.create(:user, password: 'xooxer')

    visit '/'
    log_in_as(@user.login, @user.password)
  end

  specify 'doing one exercise should unlock the other' do
    @course.refresh
    visit '/org/slug/courses'
    within '#ongoing-courses' do click_link 'mycourse' end

    expect(page).to have_content('MyExercise1')
    expect(page).not_to have_content('MyExercise2')

    submit_correct_solution('MyExercise1')

    visit '/org/slug/courses'
    within '#ongoing-courses' do click_link 'mycourse' end
    expect(page).to have_content('MyExercise2')
    expect(page).not_to have_content('(locked)')
  end

  describe 'when the deadline of an unlocked exercise depends on the unlock time' do
    specify 'the exercise must be unlocked manually' do
      pending 'Not working as expected yet'
      File.open("#{@repo.path}/MyExercise2/metadata.yml", 'ab') do |f|
        f.puts('deadline: unlock + 1 week')
      end
      @repo.add_commit_push
      @course.refresh

      visit '/org/slug/courses'
      within '#ongoing-courses' do click_link 'mycourse' end

      submit_correct_solution('MyExercise1')

      visit '/org/slug/courses'
      within '#ongoing-courses' do click_link 'mycourse' end
      expect(page).to have_content('MyExercise2 (locked)')
      expect(page).to have_content('unlock 1 new exercise')

      click_link 'unlock 1 new exercise'
      click_button 'Unlock these exercises'

      expect(page).to have_content('MyExercise2')
      expect(page).not_to have_content('(locked)')

      dl = @course.exercises.find_by_name('MyExercise2').deadline_for(@user)
      expect(dl).to be_within(10.minutes).of(Time.now + 1.week)
    end
  end

  def submit_correct_solution(exercise_on_server)
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    click_link exercise_on_server
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed
  end
end
