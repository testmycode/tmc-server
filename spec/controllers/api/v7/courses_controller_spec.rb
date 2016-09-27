require 'spec_helper'

describe CoursesController, type: :controller do

  before(:each) do
    @source_path = "#{@test_tmp_dir}/fake_source"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    @source_url = "file://#{@source_path}"
    create_bare_repo(@repo_path)
    @user = FactoryGirl.create(:user)
    @teacher = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @organization = FactoryGirl.create(:accepted_organization)
    Teachership.create(user: @teacher, organization: @organization)
  end

  describe 'GET index' do
    describe 'in JSON format' do
      def get_index_json(options = {})
        options = {
          format: 'json',
          api_version: ApiVersion::API_VERSION,
          organization_id: @organization.slug
        }.merge options
        @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64.encode64("#{@user.login}:#{@user.password}")
        get :index, options
        JSON.parse(response.body)
      end

      it 'renders all non-hidden courses in order by name' do
        FactoryGirl.create(:course, name: 'Course1', organization: @organization)
        FactoryGirl.create(:course, name: 'Course2', organization: @organization, hide_after: Time.now + 1.week)
        FactoryGirl.create(:course, name: 'Course3', organization: @organization)
        FactoryGirl.create(:course, name: 'ExpiredCourse', hide_after: Time.now - 1.week)
        FactoryGirl.create(:course, name: 'HiddenCourse', hidden: true)

        result = get_index_json

        expect(result['courses'].map { |c| c['name'] }).to eq(%w(Course1 Course2 Course3))
      end
    end
  end
end
