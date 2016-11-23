module Api
  module V8
    module Core
      module Organizations
        class CoursesController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/org/{organization_id}/courses' do
            operation :get do
              key :description, "Returns an array containing each course's collection of links"
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_organization_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, "Array containing each course's collection of links"
                schema do
                  key :title, :course
                  key :required, [:course]
                  property :course, '$ref': :CourseLinks
                end
              end
            end
          end

          def index
            unauthorize_guest!
            organization = Organization.find_by!(slug: params[:organization_slug])
            ordering = 'hidden, disabled_status, LOWER(name)'
            courses = organization.courses.ongoing.order(ordering)
            courses = courses.select { |c| c.visible_to?(current_user) }
            authorize! :read, courses
            present courses.map { |c| c.links_as_json(view_context, organization) }
          end
        end
      end
    end
  end
end
