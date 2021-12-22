# frozen_string_literal: true

require 'spec_helper'

describe OrganizationMembership, type: :model do
  it 'creates organization membership between organization and user' do
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    organization1 = FactoryBot.create :organization
    organization2 = FactoryBot.create :organization
    OrganizationMembership.create! user: user1, organization: organization1
    expect(user1.memberships).to eq([organization1])
    expect(user2.memberships).to eq([])
    expect(organization1.members).to eq([user1])
    expect(organization2.members).to eq([])
  end

  it "can't create organization membership if organization is non-existant" do
    user = FactoryBot.create :user
    organization = FactoryBot.create :organization
    expect { OrganizationMembership.create! user_id: user.id, organization_id: organization.id + 1 }.to raise_error("Validation failed: Organization can't be blank")
  end

  it "can't create organization membership if user is non-existant" do
    user = FactoryBot.create :user
    organization = FactoryBot.create :organization
    expect { OrganizationMembership.create! user_id: user.id + 1, organization_id: organization.id }.to raise_error('Validation failed: User does not exist')
  end

  it "can't create organization membership if user already member" do
    user = FactoryBot.create :user
    organization = FactoryBot.create :organization
    OrganizationMembership.create! user: user, organization: organization
    expect { OrganizationMembership.create! user: user, organization: organization }.to raise_error('Validation failed: User is already in this organization')
  end

  it "leaves organizations intact when user is destroyed, but organizations don't have ghost members" do
    user = FactoryBot.create :user
    organization1 = FactoryBot.create :organization
    organization2 = FactoryBot.create :organization
    organization3 = FactoryBot.create :organization
    OrganizationMembership.create! user: user, organization: organization1
    OrganizationMembership.create! user: user, organization: organization2
    OrganizationMembership.create! user: user, organization: organization3
    user.destroy!
    expect(Organization.all.count).to eq(3)
    expect(OrganizationMembership.all.count).to eq(0)
    expect(organization1.members).to eq([])
    expect(organization2.members).to eq([])
    expect(organization3.members).to eq([])
  end

  it "leaves users intact when organization is destroyed, but users don't have ghost memberships" do
    organization = FactoryBot.create :organization
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    user3 = FactoryBot.create :user
    OrganizationMembership.create! user: user1, organization: organization
    OrganizationMembership.create! user: user2, organization: organization
    OrganizationMembership.create! user: user3, organization: organization
    organization.destroy!
    expect(User.all.count).to eq(3)
    expect(OrganizationMembership.all.count).to eq(0)
    expect(user1.memberships).to eq([])
    expect(user2.memberships).to eq([])
    expect(user3.memberships).to eq([])
  end

  it "user's and organization's member? method works" do
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    organization1 = FactoryBot.create :organization
    organization2 = FactoryBot.create :organization
    OrganizationMembership.create! user: user1, organization: organization1
    expect(user1.member?(organization1)).to be true
    expect(user1.member?(organization2)).to be false
    expect(organization1.member?(user1)).to be true
    expect(organization1.member?(user2)).to be false
  end
end
