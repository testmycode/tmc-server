# frozen_string_literal: true

require 'spec_helper'

describe Setup::OrganizationsController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
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

  let(:new_attributes) do
    {
      name: 'New organization name',
      information: 'New information',
      website: 'http://newurl.net/'
    }
  end

  describe 'Organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET edit' do
      it 'assigns the requested organization as @organization' do
        get :edit, id: @organization.to_param
        expect(assigns(:organization)).to eq(@organization)
      end
    end

    describe 'PUT update' do
      it 'should update organization' do
        put :update, id: @organization.to_param, organization: new_attributes
        org = Organization.find_by slug: @organization.slug
        expect(org.name).to eq('New organization name')
        expect(org.information).to eq('New information')
        expect(org.website).to eq('http://newurl.net/')
      end

      it 'should assign the requested organization as @organization' do
        put :update, id: @organization.to_param, organization: new_attributes
        expect(assigns(:organization)).to eq(@organization)
      end

      it 'should redirects to the organization' do
        put :update, id: @organization.to_param, organization: new_attributes
        expect(response).to redirect_to(@organization)
      end

      describe 'with invalid params' do
        it 'should assign the organization as @organization' do
          put :update, id: @organization.to_param, organization: invalid_attributes
          expect(assigns(:organization)).to eq(@organization)
        end

        it 'should re-render the \'edit\' template' do
          put :update, id: @organization.to_param, organization: invalid_attributes.except(:slug)
          expect(response).to render_template('edit')
        end
      end

      describe 'with trying to change slug' do
        it 'should deny access' do
          put :update, id: @organization.to_param, organization: new_attributes.merge(slug: 'newslug')
          expect(response.status).to eq(401)
        end
      end
    end
  end

  describe 'As a normal user' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'should redirect to setup start page' do
        get :index
        expect(response).to redirect_to(redirect_to(setup_start_index_path))
      end
    end

    describe 'GET new' do
      it 'assigns a new organization as @organization' do
        get :new
        expect(assigns(:organization)).to be_a_new(Organization)
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

        it 'does not save organization' do
          expect do
            post :create, organization: invalid_attributes
          end.not_to change(Organization, :count).from(1)
        end

        it 're-renders the \'new\' template' do
          post :create, organization: invalid_attributes
          expect(response).to render_template('new')
        end
      end
    end

    describe 'GET edit' do
      it 'should deny access' do
        get :edit, id: @organization.to_param
        expect(response.status).to eq(401)
      end
    end

    describe 'PUT update' do
      it 'should deny access' do
        put :update, id: @organization.to_param, organization: new_attributes
        expect(response.status).to eq(401)
      end
    end
  end
end
