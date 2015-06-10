require 'spec_helper'

describe TeachersController, type: :controller do
  before :each do
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @teacher = FactoryGirl.create(:user)
  end

  describe 'As a teacher' do
    describe 'with an accepted organization' do
      before :each do
        @organization = FactoryGirl.create(:accepted_organization)
        Teachership.create!(user: @teacher, organization: @organization)
        controller.current_user = @teacher
      end

      describe 'GET index' do
        it 'lists teachers in organization' do
          get :index, organization_id: @organization.slug
          expect(assigns(:teachers)).to eq([@teacher])
        end
      end

      describe 'POST create' do
        it 'with a valid username creates a new teachership' do
          expect do
            post :create, organization_id: @organization.slug, username: @user.username
          end.to change(Teachership, :count).by(1)
        end

        it 'with a invalid username doesn\'t create a new teachership' do
          expect do
            post :create, organization_id: @organization.slug, username: 'invalid'
          end.to change(Teachership, :count).by(0)
        end

        it 'with a username that already is a teacher in the organization' do
          expect do
            post :create, organization_id: @organization.slug, username: @teacher.username
          end.to change(Teachership, :count).by(0)
        end
      end
    end

    describe 'with a pending organization' do
      before :each do
        @organization = FactoryGirl.create(:organization)
        Teachership.create!(user: @teacher, organization: @organization)
        controller.current_user = @teacher
      end

      describe 'GET index' do
        it 'denies access' do
          get :index, organization_id: @organization.slug
          expect(response.code.to_i).to eq(401)
        end
      end
      describe 'POST create' do
        it 'denies access' do
          post :create, organization_id: @organization.slug, username: @user.username
          expect(response.code.to_i).to eq(401)
        end
      end
    end
  end

  describe 'As a user' do
    before :each do
      @organization = FactoryGirl.create(:accepted_organization)
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'denies access' do
        get :index, organization_id: @organization.slug
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET new' do
      it 'denies access' do
        get :new, organization_id: @organization.slug
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST create' do
      it 'denies access' do
        post :create, organization_id: @organization.slug
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
