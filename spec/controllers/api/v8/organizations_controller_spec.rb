# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::OrganizationsController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:unaccepted_organization) { FactoryBot.create(:organization) }

  describe 'GET organizations' do
    it 'should show correct fields from the visible organizations' do
      get :index

      r = response.parsed_body

      expect(r[0]['name']).to eq(organization.name)
      expect(r[0]['information']).to eq(organization.information)
      expect(r[0]['slug']).to eq(organization.slug)
      expect(r[0]['logo_path']).to eq(organization.logo_path)
      expect(r[0]['pinned']).to eq(organization.pinned)
    end

    it 'should not show hidden organizations' do
      get :index

      r = response.parsed_body

      slugs = r.pluck('slug')
      expect(slugs).to include(organization.slug)
      expect(slugs).not_to include(unaccepted_organization.slug)
    end
  end
end
