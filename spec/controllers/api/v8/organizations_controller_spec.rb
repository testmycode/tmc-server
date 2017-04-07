require 'spec_helper'

describe Api::V8::OrganizationsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:unaccepted_organization) { FactoryGirl.create(:organization) }

  describe 'GET organizations' do
    it 'should show correct fields from the visible organizations' do
      get :index

      r = JSON.parse response.body

      expect(r[0]['name']).to eq(organization.name)
      expect(r[0]['information']).to eq(organization.information)
      expect(r[0]['slug']).to eq(organization.slug)
      expect(r[0]['logo_path']).to eq(organization.logo.url)
      expect(r[0]['pinned']).to eq(organization.pinned)
    end

    it 'should not show hidden organizations' do
      get :index

      r = JSON.parse response.body

      expect(r).not_to have_content('"name"=>"' + unaccepted_organization.name + '"')
      expect(r).not_to have_content('"information"=>"' + unaccepted_organization.information + '"')
      expect(r).not_to have_content('"slug"=>"' + unaccepted_organization.slug + '"')
    end
  end
end
