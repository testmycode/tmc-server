
module BreadcrumbHelpers # Included in ApplicationController
  def add_course_breadcrumb
    add_breadcrumb "Course #{@course.name}", course_path(@course)
  end

  def add_exercise_breadcrumb
    if @exercise
      add_breadcrumb "Exercise #{@exercise.name}", exercise_path(@exercise)
    elsif @submission && @submission.exercise_name
      add_breadcrumb "(deleted exercise #{@submission.exercise_name}", breadcrumb_no_path
    else
      raise 'Neither @exercise nor @submission.exercise_name set'
    end
  end

  def add_submission_breadcrumb
    add_breadcrumb "Submission ##{@submission.id}", submission_path(@submission)
  end

  def breadcrumb_no_path
    # Pending resolution of https://github.com/weppos/breadcrumbs_on_rails/issues/6
    # or https://github.com/weppos/breadcrumbs_on_rails/pull/32
    lambda {|*a| }
  end
end