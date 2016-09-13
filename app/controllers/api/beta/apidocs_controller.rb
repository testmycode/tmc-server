class Api::Beta::ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'TMC API documentation'
      key :description, 'TMC API documentation'
      contact do
        key :name, 'TMC API Team'
      end
      license do
        key :name, 'MIT'
      end
    end
    tag do
      key :name, 'api'
      key :description, 'API operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://cs.helsinki.fi'
      end
    end
    key :host, 'localhost:3000'
    key :basePath, '/api'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    CourseIdInformationController,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
