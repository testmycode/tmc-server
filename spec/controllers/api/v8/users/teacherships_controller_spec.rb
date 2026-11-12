# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Users::TeachershipsController, type: :controller do
  let(:teacher) { FactoryBot.create(:verified_user) }
  let(:organization) { FactoryBot.create(:accepted_organization, information: nil) }

  before do
    Teachership.create!(user: teacher, organization: organization)
    allow(controller).to receive(:doorkeeper_token).and_return(Doorkeeper::AccessToken.create!(resource_owner_id: teacher.id, scopes: 'public'))
  end

  it "lists the user's organizations, with missing information as an empty string" do
    get :index, params: { user_id: 'current' }
    expect(response.parsed_body).to match([include('organization_id' => organization.id, 'slug' => organization.slug, 'information' => '')])
  end
end
