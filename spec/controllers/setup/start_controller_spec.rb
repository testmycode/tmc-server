# frozen_string_literal: true

require 'spec_helper'

describe Setup::StartController, type: :controller do
  before :each do
    @organization1 = FactoryBot.create(:accepted_organization)
    @organization2 = FactoryBot.create(:accepted_organization)
    @teacher1 = FactoryBot.create(:user)
    @teacher2 = FactoryBot.create(:user)
    Teachership.create!(user: @teacher1, organization: @organization1)
    Teachership.create!(user: @teacher2, organization: @organization1)
    Teachership.create!(user: @teacher2, organization: @organization2)
  end

  describe 'Organization teacher' do
    describe 'GET index' do
      it 'shows single organization' do
        controller.current_user = @teacher1
        get :index
        expect(assigns(:my_organizations).count).to eq(1)
        expect(assigns(:organization)).to eq(@organization1)
      end

      it 'shows multiple organizations' do
        controller.current_user = @teacher2
        get :index
        expect(assigns(:my_organizations).count).to eq(2)
        expect(assigns(:organization)).to eq(nil)
      end
    end
  end
end
