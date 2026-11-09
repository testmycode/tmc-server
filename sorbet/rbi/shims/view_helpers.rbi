# typed: true

# `helper :all` mixes these into every view, so they run with the view's helpers, routes and
# controller helper methods. Some are also included into controllers, which Sorbet can't express.

module ApplicationHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
end

module AuthorizeCollectionHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
  include CanCan::ControllerAdditions
end

module BadUtf8Helper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module BootstrapFlashHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module CourseTimingsHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module CoursesHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module EmbeddableHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module ExercisesHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module ExtraFieldHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module FeedbackAnswersHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module FlashBlockHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module HtmlPreludeHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module PasteHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module PointsHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module SessionsHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  # Only works when included in a controller; views don't have it.
  sig { void }
  def reset_session; end
end

module SubmissionsHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end

module TwitterBreadcrumbsHelper
  include Kernel
  include ERB::Util
  include ActionView::Helpers
  include ActionController::Base::HelperMethods
  include GeneratedUrlHelpersModule
  include GeneratedPathHelpersModule
  include SessionsHelper
  include ApplicationHelper
end
