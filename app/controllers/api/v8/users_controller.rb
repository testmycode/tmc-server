class Api::V8::UsersController < Api::V8::BaseController
  include Swagger::Blocks

  swagger_path '/api/v8/user/basic_info' do
    operation :get do
      key :description, 'Returns the current user\'s username and email'
      key :operationId, 'findUsersBasicInfo'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'user'
      ]
      response 200 do
        key :description, 'User\'s username and email as json'
        schema do
          key :title, :user
          key :required, [:user]
          property :user do
            key :'$ref', :UsersBasicInfo
          end
        end
      end
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
    end
  end

  swagger_path '/api/v8/user/{user_id}/basic_info' do
    operation :get do
      key :description, 'Returns the user\'s username and email by user id'
      key :operationId, 'findUsersBasicInfoById'
      key :produces, [
          'application/json'
      ]
      key :tags, [
          'user'
      ]
      parameter '$ref': '#/parameters/path_user_id'
      response 200 do
        key :description, 'User\'s username and email by id as json'
        schema do
          key :title, :user
          key :required, [:user]
          property :user do
            key :'$ref', :UsersBasicInfo
          end
        end
      end
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
    end
  end

  def basic_info
    unauthorize_guest! if current_user.guest?
    user = current_user
    user = User.find_by!(id: params[:user_id]) if params[:user_id]
    authorize! :read, user

    present(
      username: user.login,
      email: user.email
    )
  end
end
