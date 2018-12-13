# frozen_string_literal: true

class ModelSolutionTokenUsedsController < ApplicationController
  before_action :set_model_solution_token_used, only: [:show, :edit, :update, :destroy]
  before_action :only_admins

  # GET /model_solution_token_useds
  def index
    @model_solution_token_useds = ModelSolutionTokenUsed.all
  end

  # GET /model_solution_token_useds/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_model_solution_token_used
      @model_solution_token_used = ModelSolutionTokenUsed.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def model_solution_token_used_params
      params.require(:model_solution_token_used).permit(:user_id, :course_id, :exercise_name)
    end
end
