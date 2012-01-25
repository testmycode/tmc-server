require 'tailoring'

module ApplicationHelper
  def tailoring
    Tailoring.get
  end

  def labeled(label, tags)
    if tags =~ /id\s*=\s*"([^"]+)"/
      raw('<label for="' + h($1) + '">' + h(label) + '</label>' + tags)
    else
      raise 'Cannot label a tag without an id'
    end
  end
  
  def labeled_field(label, tags)
    raw('<div class="field">' + labeled(label, tags) + '</div>')
  end
  
  def use_datatables(table_selector, options = {})
    options = {
      :bJQueryUI => true,
      :bSort => false
    }.merge options
    script =<<EOS
<script type="text/javascript">
<!--
$(document).ready(function() {
  $('#{escape_javascript table_selector}').dataTable(#{options.to_json});
});
//-->
</script>
EOS
    raw(script)
  end
  
  def breadcrumb
    parts = []
    
    parts << link_to('TMC', root_path)
    
    action = "#{@controller_name}##{@action_name}"
    
    if @course && !@course.new_record?
      parts << link_to(raw("Course #{breadcrumb_resource(@course.name)}"), @course)
      
      if @exercise && !@exercise.new_record? && @exercise.course == @course
        parts << link_to(raw("Exercise #{breadcrumb_resource(@exercise.name)}"), exercise_path(@exercise))
        
        if @submission && !@submission.new_record? && @submission.exercise == @exercise
          parts << link_to(raw("Submission #{breadcrumb_resource('#' + @submission.id.to_s)}"), submission_path(@submission))
        elsif @solution
          parts << link_to('Suggested solution', exercise_solution_path(@exercise))
        end
        
      elsif @submission && !@submission.new_record?
        parts << raw("(deleted exercise #{breadcrumb_resource(@submission.exercise_name)})")
        parts << link_to(raw("Submission #{breadcrumb_resource('#' + @submission.id.to_s)}"), submission_path(@submission))
      elsif action == 'submissions#index'
        parts << link_to("Submissions", course_submissions_path(@course))
      end
    elsif @user
      if @user.new_record?
        parts << link_to("Sign up", new_user_path)
      else
        parts << link_to("User account", user_path)
      end
    end
    raw(parts.join(' &raquo; '))
  end
  
private
  def breadcrumb_resource(name)
    content_tag(:span, h(name), :class => 'breadcrumb-resource')
  end
end
