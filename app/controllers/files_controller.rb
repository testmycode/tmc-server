# frozen_string_literal: true

# Shows the files of a submission.
class FilesController < ApplicationController
  skip_authorization_check

  # Should eventualy be removed
  # This exists just to provide comapatability with old files url format
  # Cannot be redirected in routes, as rack_base_uri cannot be used for redirects.
  # - Jamox / 12.7.2014
  def index
    redirect_to submission_path(params[:submission_id], anchor: 'files')
  end
end
