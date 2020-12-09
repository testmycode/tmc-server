# frozen_string_literal: true

require 'spec_helper'

describe OrganizationsController, type: :controller do
  before :each do
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
  end

  let(:valid_attributes) do
    {
      name: 'TestOrganization',
      slug: 'test-organization',
      verified: true
    }
  end

  let(:invalid_attributes) do
    {
      name: nil,
      slug: 'test organization',
      verified: nil
    }
  end

  describe 'As an admin' do
    before :each do
      controller.current_user = @admin
    end

    describe 'GET index' do
      it 'shows visible courses in order by name, split into ongoing and expired' do
        @organization = Organization.create! valid_attributes
        @courses = [
          FactoryGirl.create(:course, name: 'SomeTestCourse', organization: @organization),
          FactoryGirl.create(:course, name: 'ExpiredCourse', organization: @organization, hide_after: Time.now - 1.week),
          FactoryGirl.create(:course, name: 'AnotherTestCourse', organization: @organization)
        ]

        get :show, id: @organization.slug

        expect(assigns(:ongoing_courses).map(&:name)).to eq(%w[SomeTestCourse AnotherTestCourse])
        #expect(assigns(:expired_courses).map(&:name)).to eq(['ExpiredCourse'])
      end
    end

    describe 'GET list_requests' do
      before :each do
        @org1 = FactoryGirl.create(:organization)
        @org2 = FactoryGirl.create(:accepted_organization)
        @org3 = FactoryGirl.create(:organization)
      end

      it 'lists only pending organization requests' do
        get :list_requests, {}
        expect(assigns(:unverified_organizations).sort).to eq([@org1, @org3].sort)
      end
    end

    describe 'POST verify' do
      it 'verifies the organization' do
        org = Organization.init(valid_attributes, @user)
        post :verify, id: org.to_param
        org.reload
        expect(org.verified).to eq(true)
      end
    end

    describe 'POST disable' do
      it 'sets the organization disabled flag to true' do
        org = Organization.init(valid_attributes, @user)
        post :disable, id: org.to_param, organization: { disabled_reason: 'reason' }
        org.reload
        expect(org.disabled).to eq(true)
      end
    end
  end

  describe 'As a teacher' do
    before :each do
      controller.current_user = @user
    end

    describe 'POST toggle_visibility' do
      it 'toggles value of hidden field between true and false' do
        org = FactoryGirl.create(:accepted_organization)
        Teachership.create(user_id: @user.id, organization_id: org.id)
        post :toggle_visibility, id: org.to_param
        org.reload
        expect(org.hidden).to be true
        expect(response).to redirect_to(organization_path)
      end
    end
  end

  describe 'As a normal user' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'assigns all organizations as @organizations' do
        organization = Organization.create! valid_attributes
        get :index, {}
        expect(assigns(:organizations)).to eq([organization])
      end
    end

    describe 'GET show' do
      it 'assigns the requested organization as @organization' do
        organization = Organization.create! valid_attributes
        get :show, id: organization.to_param
        expect(assigns(:organization)).to eq(organization)
      end
    end

    describe 'GET new' do
      it 'should redirect to new setup location' do
        get :new
        expect(response).to redirect_to(new_setup_organization_path)
      end
    end

    describe 'GET list_requests' do
      it 'denies access' do
        get :list_requests, {}
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'POST verify' do
      it 'denies access' do
        org = Organization.init(valid_attributes, @user)
        post :verify, id: org.to_param
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'POST disable' do
      it 'denies access' do
        org = Organization.init(valid_attributes, @user)
        post :disable, id: org.to_param
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'POST toggle_visibility' do
      it 'denies access' do
        org = FactoryGirl.create(:accepted_organization)
        post :toggle_visibility, id: org.to_param
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
