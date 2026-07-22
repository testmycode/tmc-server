# frozen_string_literal: true

require 'spec_helper'

# Exercises the additive, feature-flagged courses.mooc.fi (secret-project-331) token
# introspection branch in Api::V8::BaseController#authenticate_user!. Mirrors the
# UselessController pattern from base_controller_spec.rb.
class MoocTokenUselessController < Api::V8::BaseController
end

RSpec.describe Api::V8::BaseController, type: :controller do
  controller MoocTokenUselessController do
    skip_authorization_check # not testing cancan here
    def index
      render plain: 'Success'
    end
  end

  subject(:current_user) { assigns[:current_user] }

  let(:sub) { '11111111-2222-3333-4444-555555555555' }
  let(:bearer) { 'sp331-access-token' }

  def result(scopes: ['exercise-services'], upstream_id: nil, subject_id: sub)
    CoursesMoocFiTokenIntrospector::Result.new(
      sub: subject_id, scopes: scopes, upstream_id: upstream_id, expires_at: Time.now + 3600
    )
  end

  # Save/restore the flag so tests never leak global state.
  around do |example|
    original = Rails.configuration.x.accept_courses_mooc_fi_tokens
    example.run
    Rails.configuration.x.accept_courses_mooc_fi_tokens = original
  end

  before do
    # No native Doorkeeper token in these tests unless a context overrides it.
    allow(controller).to receive(:doorkeeper_token).and_return(nil)
    request.headers['Authorization'] = "Bearer #{bearer}"
  end

  context 'when the flag is off (default behaviour, regression)' do
    before { Rails.configuration.x.accept_courses_mooc_fi_tokens = false }

    it 'never introspects and resolves to Guest' do
      expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
      get :index
      expect(current_user).to be_guest
    end

    it 'does not even read the bearer token when the flag is off, despite a bearer header' do
      # The flag is the first operand of the && guard, so short-circuit evaluation must skip
      # bearer_token (and therefore introspection) entirely even though an unknown bearer is
      # present. Pins the flag-off path's evaluation-order invariant.
      expect(controller).not_to receive(:bearer_token)
      expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
      get :index
      expect(current_user).to be_guest
    end

    it 'still authenticates a native Doorkeeper token' do
      user = FactoryBot.create(:user)
      allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: user.id, acceptable?: true))
      get :index
      expect(current_user.id).to eq(user.id)
    end
  end

  context 'when the flag is on' do
    before { Rails.configuration.x.accept_courses_mooc_fi_tokens = true }

    it 'still prefers a native Doorkeeper token over introspection' do
      user = FactoryBot.create(:user)
      allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: user.id, acceptable?: true))
      expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
      get :index
      expect(current_user.id).to eq(user.id)
    end

    it 'resolves the mapped user for a valid introspected token' do
      user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).with(bearer).and_return(result)
      get :index
      expect(current_user.id).to eq(user.id)
    end

    it 'resolves to Guest when the exercise-services scope is missing' do
      FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(result(scopes: ['other-scope']))
      get :index
      expect(current_user).to be_guest
    end

    it 'resolves to Guest when introspection fails' do
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(nil)
      get :index
      expect(current_user).to be_guest
    end

    it 'resolves to Guest and warns when the subject is not a valid UUID' do
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
        .and_return(result(subject_id: 'not-a-uuid'))
      expect(Rails.logger).to receive(:warn).with(/not a valid UUID/)
      get :index
      expect(current_user).to be_guest
    end

    it 'resolves to Guest and warns when the mapped user is an administrator' do
      FactoryBot.create(:admin, courses_mooc_fi_user_id: sub)
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(result)
      expect(Rails.logger).to receive(:warn).with(/administrator/)
      get :index
      expect(current_user).to be_guest
    end

    it 'resolves to Guest and warns when the mapped user holds a teachership' do
      user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      Teachership.create!(user: user, organization: FactoryBot.create(:organization))
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(result)
      expect(Rails.logger).to receive(:warn).with(/teacher/)
      get :index
      expect(current_user).to be_guest
    end

    it 'resolves to Guest and warns when the mapped user holds an assistantship' do
      user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
      Assistantship.create!(user: user, course: FactoryBot.create(:course))
      allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(result)
      expect(Rails.logger).to receive(:warn).with(/assistant/)
      get :index
      expect(current_user).to be_guest
    end

    context 'upstream_id fallback + backfill' do
      it 'resolves via upstream_id and backfills courses_mooc_fi_user_id' do
        user = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
          .and_return(result(upstream_id: user.id))
        get :index
        expect(current_user.id).to eq(user.id)
        expect(user.reload.courses_mooc_fi_user_id).to eq(sub)
      end

      it 'does not authenticate an administrator via the upstream_id fallback' do
        admin = FactoryBot.create(:admin, courses_mooc_fi_user_id: nil)
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
          .and_return(result(upstream_id: admin.id))
        get :index
        expect(current_user).to be_guest
      end

      it 'resolves to Guest when neither the subject nor upstream_id match a user' do
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
          .and_return(result(upstream_id: 999_999))
        get :index
        expect(current_user).to be_guest
      end

      it 'refuses when upstream_id maps to a user already bound to a different subject' do
        other_sub = '99999999-8888-7777-6666-555555555555'
        user = FactoryBot.create(:user, courses_mooc_fi_user_id: other_sub)
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
          .and_return(result(upstream_id: user.id))
        expect(Rails.logger).to receive(:warn).with(/already bound to a different/)
        get :index
        expect(current_user).to be_guest
        expect(user.reload.courses_mooc_fi_user_id).to eq(other_sub)
      end

      it 'trusts the winner of the backfill race when the unique index rejects the write' do
        # Two concurrent requests for the same subject: this one loses the unique-index race.
        # The rescue must re-read the authoritative mapping rather than fail to Guest.
        winner = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        loser = FactoryBot.create(:user, courses_mooc_fi_user_id: nil)
        # Simulate the racing request committing first, then our write blowing up. update_all
        # rather than update_column, which is the stubbed method.
        allow_any_instance_of(User).to receive(:update_column) do
          User.where(id: winner.id).update_all(courses_mooc_fi_user_id: sub)
          raise ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint'
        end
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect)
          .and_return(result(upstream_id: loser.id))

        get :index

        expect(current_user.id).to eq(winner.id)
      end
    end

    context 'bearer header parsing' do
      it 'does not introspect when there is no Authorization header' do
        request.headers['Authorization'] = nil
        expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
        get :index
        expect(current_user).to be_guest
      end

      it 'does not introspect a non-Bearer authorization scheme' do
        request.headers['Authorization'] = 'Basic dXNlcjpwYXNz'
        expect(CoursesMoocFiTokenIntrospector).not_to receive(:introspect)
        get :index
        expect(current_user).to be_guest
      end

      it 'accepts a lower-case bearer scheme and passes the raw token through' do
        user = FactoryBot.create(:user, courses_mooc_fi_user_id: sub)
        request.headers['Authorization'] = "bearer #{bearer}"
        allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).with(bearer).and_return(result)
        get :index
        expect(current_user.id).to eq(user.id)
      end
    end
  end
end
