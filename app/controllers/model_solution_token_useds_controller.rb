# typed: strict
# frozen_string_literal: true

class ModelSolutionTokenUsedsController < ApplicationController
  extend T::Sig
  skip_authorization_check
  before_action :only_admins!
  before_action :set_model_solution_token_used, only: [:show]

  # GET /model_solution_token_useds
  sig { void }
  def index
    @model_solution_token_useds = T.let(ModelSolutionTokenUsed.all, T.nilable(ActiveRecord::Relation))
  end

  # GET /model_solution_token_useds/1
  sig { void }
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    sig { void }
    def set_model_solution_token_used
      @model_solution_token_used = T.let(ModelSolutionTokenUsed.find(params[:id]), T.nilable(ModelSolutionTokenUsed))
    end

    # Only allow a trusted parameter "white list" through.
    sig { returns(ActionController::Parameters) }
    def model_solution_token_used_params
      params.require(:model_solution_token_used).permit(:user_id, :course_id, :exercise_name)
    end
end
