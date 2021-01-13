# frozen_string_literal: true

module EmbeddableHelper
  def remove_x_frame_options_header_when_bare_layout
    response.headers.except! 'X-Frame-Options' if @bare_layout
  end
end
