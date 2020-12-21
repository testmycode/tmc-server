# frozen_string_literal: true

require 'spec_helper'

describe Api::Beta::ParticipantController, type: :request do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @admin = FactoryGirl.create(:admin, password: 'xooxer')
    @user = FactoryGirl.create(:user, login: 'user', password: 'xooxer')
    allow(SiteSetting).to receive(:value).with('valid_clients')
               .and_return([{ 'name' => 'cli', 'min_version' => '0.1.1' }])
  end

  def get_paste(id, user)
    get "/paste/#{id}.json", { api_version: ApiVersion::API_VERSION }, { 'Accept' => 'application/json', 'HTTP_AUTHORIZATION' => basic_auth(user) }
  end

  describe 'TMC-api with JSON' do
    describe 'Obsolete clients' do
      it 'show when no api version is set' do
        get_courses_json_with(client: '')
        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json).to have_key('obsolete_client')
      end

      describe 'with API version correctly set' do
        it 'not valid client client' do
          get_courses_json_with(api_version: ApiVersion::API_VERSION, client: 'a')
          json = JSON.parse(response.body)
          expect(json).to have_key('error')
          expect(json).to have_key('obsolete_client')
        end

        it 'not valid client client and client version' do
          get_courses_json_with(api_version: ApiVersion::API_VERSION, client: 'a', client_version: '1')
          json = JSON.parse(response.body)
          expect(json).to have_key('error')
          expect(json).to have_key('obsolete_client')
        end

        describe 'with valid client' do
          it 'invalid client version' do
            get_courses_json_with(api_version: ApiVersion::API_VERSION, client: 'cli', client_version: '1')
            json = JSON.parse(response.body)
            expect(json).to have_key('error')
          end
          it 'old client version' do
            get_courses_json_with(api_version: ApiVersion::API_VERSION, client: 'cli', client_version: '0.0.1')
            json = JSON.parse(response.body)
            expect(json).to have_key('error')
            expect(json).to have_key('obsolete_client')
          end
          it 'new enough client version' do
            # we don't get much, but we wan't to see that the prefilter is working.
            get_courses_json_with(api_version: ApiVersion::API_VERSION, client: 'cli', client_version: '0.1.1')
            json = JSON.parse(response.body)
            expect(json).not_to have_key('obsolete_client')
          end
        end
      end
      # get_courses_json_with(client: "", client_version: "1")
    end
  end
end

def get_courses_json_with(hash = {})
  get organization_course_path({ id: 1, organization_id: 1, format: :json }.merge(hash))
end
