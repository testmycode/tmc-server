require 'spec_helper'

feature 'Admin propagates template changes to all courses cloned from template', feature: true do
  include IntegrationTestActions

  before :each do
    @organization1 = FactoryGirl.create(:accepted_organization, slug: 'slug1')
    @organization2 = FactoryGirl.create(:accepted_organization, slug: 'slug2')

    @admin = FactoryGirl.create :admin, password: 'xooxer'
    @teacher1 = FactoryGirl.create :user, password: 'teacher1'
    @teacher2 = FactoryGirl.create :user, password: 'teacher2'

    Teachership.create! user: @teacher1, organization: @organization1
    Teachership.create! user: @teacher2, organization: @organization2

    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)

    FactoryGirl.create :course_template, name: 'template', title: 'template', source_url: @repo_path

    visit '/'
    log_in_as @teacher1.login, 'teacher1'
    create_course_from_template name: 'course', organization_slug: @organization1.slug

    log_out
    log_in_as @teacher2.login, 'teacher2'
    create_course_from_template name: 'course', organization_slug: @organization2.slug

    log_out
  end

  scenario 'Admin refreshes template, courses get updated' do
    course = Course.find_by_name!('course')
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('MyExercise')
    repo.add_commit_push

    log_in_as @admin.login, 'xooxer'
    visit '/course_templates'
    click_link 'Refresh'

    visit '/'
    click_link @organization1.name
    click_link 'course'
    expect(page).to have_content('MyExercise')

    visit '/'
    click_link @organization2.name
    click_link 'course'
    expect(page).to have_content('MyExercise')
  end

  scenario 'Submissions are not shared among courses created from same template' do
    course = Course.find_by_name!('course')
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('MyExercise')
    repo.add_commit_push

    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    log_in_as @admin.login, 'xooxer'
    visit '/course_templates'
    click_link 'Refresh'

    user = FactoryGirl.create :user, password: 'foobar'

    log_out
    log_in_as user.login, 'foobar'

    visit '/'
    click_link @organization1.name
    click_link 'course'
    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'

    visit '/'
    click_link @organization1.name
    click_link 'course'
    first(:link, 'MyExercise').click
    expect(page).to have_content(user.login)
    expect(page).not_to have_content('No submissions yet.')

    visit '/'
    click_link @organization2.name
    click_link 'course'
    first(:link, 'MyExercise').click
    expect(page).to have_content('No submissions yet.')
  end

end
