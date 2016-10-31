require 'spec_helper'

class UselessController < Api::V8::BaseController; end

RSpec.describe Api::V8::BaseController, type: :controller do
  controller UselessController do
    def index
      render text: 'Success'
    end
  end

  describe 'current_user' do
    subject(:current_user) { assigns[:current_user] }
    let(:token) { nil }

    before :each do
      controller.stub(:doorkeeper_token) { token }
      get :index
    end

    context 'when not logged in' do
      it { is_expected.to be_guest }
    end

    context 'when logged in' do
      let(:user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: user.id }
      it { expect(subject.id).to be user.id }
    end
  end

  describe 'authentication' do
    before :each do
      controller.stub(:doorkeeper_token) { token }
    end
    context 'with an invalid token' do
      let(:token) { double resource_owner_id: -1 }
      it 'request is not successful' do
        expect { get :index }.to raise_error(RuntimeError)
      end
    end
  end
end
