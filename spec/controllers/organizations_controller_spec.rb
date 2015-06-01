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
      acceptance_pending: false
    }
  end

  let(:invalid_attributes) do
    {
      name: nil,
      slug: 'test organization',
      acceptance_pending: nil
    }
  end

  describe 'As an admin' do
    before :each do
      controller.current_user = @admin
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

    describe 'DELETE destroy' do
      it 'destroys the requested organization' do
        organization = Organization.create! valid_attributes
        expect do
          delete :destroy, id: organization.to_param
        end.to change(Organization, :count).by(-1)
      end

      it 'redirects to the organizations list' do
        organization = Organization.create! valid_attributes
        delete :destroy, id: organization.to_param
        expect(response).to redirect_to(organizations_url)
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
        expect(assigns(:requested_organizations)).to eq([@org1, @org3])
      end
    end

    describe 'POST accept' do
      it 'accepts the organization request' do
        org = Organization.init(valid_attributes.merge(acceptance_pending: true), @user)
        post :accept, id: org.to_param
        org.reload
        expect(org.acceptance_pending).to eq(false)
      end
    end

    describe 'POST reject' do
      it 'sets the organization rejected flag to true' do
        org = Organization.init(valid_attributes.merge(acceptance_pending: true), @user)
        post :reject, id: org.to_param, organization: { rejected_reason: 'reason' }
        org.reload
        expect(org.rejected).to eq(true)
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

    describe 'DELETE destroy' do
      it 'denies access' do
        organization = Organization.create! valid_attributes
        delete :destroy, id: organization.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET list_requests' do
      it 'denies access' do
        get :list_requests, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST accept' do
      it 'denies access' do
        org = Organization.init(valid_attributes.merge(acceptance_pending: true), @user)
        post :accept, id: org.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST reject' do
      it 'denies access' do
        org = Organization.init(valid_attributes.merge(acceptance_pending: true), @user)
        post :reject, id: org.to_param
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
