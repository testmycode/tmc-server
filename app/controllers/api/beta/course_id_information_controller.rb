class Api::Beta::CourseIdInformationController < Api::Beta::BaseController
  include Swagger::Blocks

  swagger_path '/course_id_information' do
    operation :get do
      key :description, 'Returns list of course IDs'
      key :produces, [
        'application/json',
      ]
      response 200 do
        key :description, 'list of course IDs'
        schema do
          key :type, :array
          items do
            key :type, :integer
          end
        end
      end
      response 401 do
        key :description, 'User is not authenticated!'
        schema do
          key :type, :array
          items do
            key :type, :string
          end
        end
      end
    end
  end

  before_action :doorkeeper_authorize!, :scopes => [:public]

  def index
    course_ids = Course.order(:id).where(hidden: false).enabled.pluck(:id)
    present(course_ids)
  end
end
