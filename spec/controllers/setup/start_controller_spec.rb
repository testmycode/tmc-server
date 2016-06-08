require 'spec_helper'

describe Setup::StartController, type: :controller do

  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @teacher = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
  end

  describe 'Organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET index' do
      it 'shows own organization' do
        get :index
        expect(assigns(:organization)).to eq(@organization)
      end
    end
  end
end
