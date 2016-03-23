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

        expect(assigns(:ongoing_courses).map(&:name)).to eq(%w(AnotherTestCourse SomeTestCourse))
        expect(assigns(:expired_courses).map(&:name)).to eq(['ExpiredCourse'])
      end
    end

    describe 'PUT update' do
      describe 'with valid params' do
        let(:new_attributes) do
          {
            information: 'Changed information'
          }
        end

        it 'updates the requested organization' do
          organization = Organization.create! valid_attributes
          put :update, id: organization.to_param, organization: new_attributes
          organization.reload
          expect(organization.information).to eq('Changed information')
        end

        it 'assigns the requested organization as @organization' do
          organization = Organization.create! valid_attributes
          put :update, id: organization.to_param, organization: valid_attributes
          expect(assigns(:organization)).to eq(organization)
        end

        it 'redirects to the organization' do
          organization = Organization.create! valid_attributes
          put :update, id: organization.to_param, organization: valid_attributes
          expect(response).to redirect_to(organization)
        end
      end

      describe 'with invalid params' do
        it 'assigns the organization as @organization' do
          organization = Organization.create! valid_attributes
          put :update, id: organization.to_param, organization: invalid_attributes
          expect(assigns(:organization)).to eq(organization)
        end

        it 're-renders the \'edit\' template' do
          organization = Organization.create! valid_attributes
          put :update, id: organization.to_param, organization: invalid_attributes
          expect(response).to render_template('edit')
        end
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

    describe 'PUT update' do
      it 'updates the requested organization if slug not changed' do
        org = FactoryGirl.create(:accepted_organization)
        Teachership.create(user_id: @user.id, organization_id: org.id)
        put :update, id: org.to_param, organization: { name: 'New organization name' }
        org.reload
        expect(org.name).to eq('New organization name')
        expect(response).to redirect_to(organization_path)
      end
    end

    describe 'PUT update with slug change' do
      it 'denies access' do
        org = FactoryGirl.create(:accepted_organization)
        Teachership.create(user_id: @user.id, organization_id: org.id)
        put :update, id: org.to_param, organization: { slug: 'newslug' }
        expect(response.code.to_i).to eq(401)
      end
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
      it 'assigns a new organization as @organization' do
        get :new, {}
        expect(assigns(:organization)).to be_a_new(Organization)
      end
    end

    describe 'GET edit' do
      it 'assigns the requested organization as @organization' do
        organization = Organization.create! valid_attributes
        get :edit, id: organization.to_param
        expect(assigns(:organization)).to eq(organization)
      end
    end

    describe 'POST create' do
      describe 'with valid params' do
        it 'creates a new Organization' do
          expect do
            post :create, organization: valid_attributes
          end.to change(Organization, :count).by(1)
        end

        it 'assigns a newly created organization as @organization' do
          post :create, organization: valid_attributes
          expect(assigns(:organization)).to be_a(Organization)
          expect(assigns(:organization)).to be_persisted
        end

        it 'redirects to the created organization' do
          post :create, organization: valid_attributes
          expect(response).to redirect_to(Organization.last)
        end
      end

      describe 'with invalid params' do
        it 'assigns a newly created but unsaved organization as @organization' do
          post :create, organization: invalid_attributes
          expect(assigns(:organization)).to be_a_new(Organization)
        end

        it 're-renders the \'new\' template' do
          post :create, organization: invalid_attributes
          expect(response).to render_template('new')
        end
      end
    end

    describe 'PUT update' do
      it 'denies access' do
        organization = Organization.create! valid_attributes
        put :update, id: organization.to_param, organization: {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET list_requests' do
      it 'denies access' do
        get :list_requests, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST verify' do
      it 'denies access' do
        org = Organization.init(valid_attributes, @user)
        post :verify, id: org.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST disable' do
      it 'denies access' do
        org = Organization.init(valid_attributes, @user)
        post :disable, id: org.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST toggle_visibility' do
      it 'denies access' do
        org = FactoryGirl.create(:accepted_organization)
        post :toggle_visibility, id: org.to_param
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
