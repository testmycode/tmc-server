# frozen_string_literal: true

module Api
  module V8
    module Organizations
      class MembershipsController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/org/{organization_slug}/memberships' do
          operation :post do
            key :description, "Creates a membership to the organization for the current user."
            key :operationId, 'createUserOrganizationMembership'
            key :produces, ['application/json']
            key :tags, ['organization', 'membership']
            parameter '$ref': '#/parameters/path_organization_slug'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, "status 'ok' and creates the membership"
              schema do
                key :title, :status
                key :required, [:status]
                property :status, type: :string, example: 'Membership created to Test-organization for student1@example.com'
              end
            end
          end
        end

        swagger_path '/api/v8/org/{organization_slug}/memberships' do
          operation :get do
            key :description, "Returns a list of organization members."
            key :operationId, 'findUserOrganizationMembership'
            key :produces, ['application/json']
            key :tags, ['organization', 'membership']
            parameter '$ref': '#/parameters/path_organization_slug'
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
            response 200 do
              key :description, 'List of members'
              schema do
                key :title, :members
                key :required, [:members]
                property :members do
                  key :type, :array
                  items do
                    key :type, :object
                    property :id do
                      key :type, :integer
                    end
                    property :email do
                      key :type, :string
                    end
                  end
                end
              end
            end
          end
        end

        def create
          unauthorize_guest!

          organization = Organization.find_by!(slug: params[:organization_slug])
          authorize! :read, organization

          if organization.member?(current_user)
            present(status: "#{current_user.email} is already a member of #{organization.name}")
          else
            OrganizationMembership.create! user: current_user, organization: organization
            present(status: "Membership created to #{organization.name} for #{current_user.email}")
          end
        end

        def index
          unauthorize_guest!

          organization = Organization.find_by!(slug: params[:organization_slug])
          authorize! :teach, organization

          data = organization.members.map do |u|
            user_fields = u.user_field_values.map { |o| [o.field_name, o.value] }.to_h
            d = {
              id: u.id,
              email: u.email,
            }
          end
          present(members: data)
        end

      end
    end
  end
end
  