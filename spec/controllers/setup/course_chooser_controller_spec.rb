# frozen_string_literal: true

require 'spec_helper'

describe Setup::CourseChooserController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
    @ct1 = FactoryGirl.create(:course_template)
    @ct2 = FactoryGirl.create(:course_template)
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET index' do
      it 'should list available templates' do
        get :index, params: { organization_id: @organization.slug }
        expect(assigns(:organization)).to eq(@organization)
        expect(assigns(:course_templates).map(&:name)).to eq(%W[#{@ct1.name} #{@ct2.name}])
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'should not allow access' do
        get :index, params: { organization_id: @organization.slug }
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
