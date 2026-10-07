# frozen_string_literal: true

require 'spec_helper'

class MoocTokenUselessController < Api::V8::BaseController
end

RSpec.describe Api::V8::BaseController, type: :controller do
  controller MoocTokenUselessController do
    skip_authorization_check
    def index
      render plain: 'Success'
    end
  end

  subject(:current_user) { assigns[:current_user] }

  let(:sub) { '11111111-2222-3333-4444-555555555555' }
  let(:bearer) { 'sp331-access-token' }

  def result(upstream_id: nil, subject_id: sub)
    CoursesMoocFiTokenIntrospector::Result.new(sub: subject_id, upstream_id: upstream_id, expires_at: Time.now + 3600)
  end

  def introspection_returns(value)
    allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).with(bearer).and_return(value)
  end

  around do |example|
    original = Rails.configuration.x.accept_courses_mooc_fi_tokens
    example.run
    Rails.configuration.x.accept_courses_mooc_fi_tokens = original
  end

  before do
    allow(controller).to receive(:doorkeeper_token).and_return(nil)
    request.headers['Authorization'] = "Bearer #{bearer}"
  end

  context 'when the flag is off' do
    before { Rails.configuration.x.accept_courses_mooc_fi_tokens = false }

    it 'never introspects a bearer token' do
      expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
      get :index
      expect(current_user).to be_guest
    end
  end

  context 'when the flag is on' do
    before { Rails.configuration.x.accept_courses_mooc_fi_tokens = true }

    it 'prefers a native Doorkeeper token' do
      user = FactoryBot.create(:user)
      allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: user.id, acceptable?: true))
      expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
      get :index
      expect(current_user).to eq(user)
    end

    it 'resolves the user bound to the token subject' do
      user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      introspection_returns(result)
      get :index
      expect(current_user).to eq(user)
    end

    it 'accepts a lower-case bearer scheme' do
      user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      request.headers['Authorization'] = "bearer #{bearer}"
      introspection_returns(result)
      get :index
      expect(current_user).to eq(user)
    end

    it 'resolves to Guest when courses.mooc.fi rejects the token' do
      introspection_returns(nil)
      get :index
      expect(response).to have_http_status(:ok)
      expect(current_user).to be_guest
    end

    it 'answers 503 when courses.mooc.fi cannot check the token' do
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
        .and_raise(CoursesMoocFiTokenIntrospector::Unavailable, 'introspection answered HTTP 502')
      expect(Rails.logger).to receive(:error).with(/introspection answered HTTP 502/)
      get :index
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include('could not verify your login')
    end

    it 'does not swallow a database error during the user lookup' do
      introspection_returns(result)
      allow(User).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect { get :index }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    {
      'no Authorization header' => nil,
      'a non-Bearer scheme' => 'Basic dXNlcjpwYXNz'
    }.each do |description, header|
      it "does not introspect with #{description}" do
        request.headers['Authorization'] = header
        expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
        get :index
        expect(current_user).to be_guest
      end
    end

    context 'with elevated users' do
      controller MoocTokenUselessController do
        skip_authorization_check
        def index
          render json: {
            administrator: current_user.administrator?,
            manage_all: can?(:manage, :all),
            teach: can?(:teach, Organization.find(params[:organization_id]))
          }
        end
      end

      let(:organization) { FactoryBot.create(:organization) }

      before { introspection_returns(result) }

      it 'keeps an administrator an administrator' do
        FactoryBot.create(:admin, courses_mooc_fi_user_id: sub)
        get :index, params: { organization_id: organization.id }
        expect(JSON.parse(response.body)).to include('administrator' => true, 'manage_all' => true)
      end

      it 'keeps a teacher a teacher' do
        teacher = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
        Teachership.create!(user: teacher, organization: organization)
        get :index, params: { organization_id: organization.id }
        expect(JSON.parse(response.body)).to include('administrator' => false, 'teach' => true)
      end
    end

    context 'when no user is bound to the subject yet' do
      it 'binds the user courses.mooc.fi reports as upstream_id' do
        user = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        introspection_returns(result(upstream_id: user.id))
        get :index
        expect(current_user).to eq(user)
        expect(user.reload.courses_mooc_fi_user_id).to eq(sub)
      end

      it 'resolves a user stored with an upper-case id through upstream_id' do
        user = FactoryBot.create(:user)
        User.where(id: user.id).update_all(courses_mooc_fi_user_id: sub.upcase)
        introspection_returns(result(upstream_id: user.id))
        get :index
        expect(current_user).to eq(user)
      end

      it 'resolves to Guest when upstream_id matches no user' do
        introspection_returns(result(upstream_id: 999_999))
        get :index
        expect(current_user).to be_guest
      end

      it 'refuses a user bound to a different subject' do
        other_sub = '99999999-8888-7777-6666-555555555555'
        user = FactoryBot.create(:user, courses_mooc_fi_user_id: other_sub)
        introspection_returns(result(upstream_id: user.id))
        expect(Rails.logger).to receive(:warn).with(/bound to a different/)
        get :index
        expect(current_user).to be_guest
        expect(user.reload.courses_mooc_fi_user_id).to eq(other_sub)
      end

      it 'resolves the winner when a concurrent request binds the subject first' do
        winner = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        loser = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        allow_any_instance_of(User).to receive(:update_column) do
          User.where(id: winner.id).update_all(courses_mooc_fi_user_id: sub)
          raise ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint'
        end
        introspection_returns(result(upstream_id: loser.id))
        get :index
        expect(current_user).to eq(winner)
      end
    end
  end
end
