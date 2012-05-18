require 'tailoring'

module ApplicationHelper
  def tailoring
    Tailoring.get
  end
  
  
  def labeled(label, tags = nil, options = {}, &block)
    if tags.is_a?(Hash) && options.empty?
      options = tags
      tags = nil
    end
    
    options = {
      :order => :label_first,
      :class => nil
    }.merge(options)
    
    tags = capture(&block) if tags == nil && block != nil
    tags = tags.html_safe
    
    if tags =~ /id\s*=\s*"([^"]+)"/
      target = ' for="' + $1 + '"'
    else
      raise 'Cannot label a tag without an id'
    end
    
    cls = []
    cls << options[:order].to_s
    cls << h(options[:class].to_s) if options[:class]
    cls = ' class="' + cls.join(' ') + '"'
    
    label = '<label' + target + cls + '>' + h(label) + '</label>'
    label = label.html_safe
    
    case options[:order]
    when :label_first
      label + tags
    when :label_last
      tags + label
    else
      raise 'invalid :order option for labeled()'
    end
  end
  
  def labeled_field(label, tags = nil, options = {}, &block)
    raw('<div class="field">' + labeled(label, tags, options, &block) + '</div>')
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

  def link_back
    raw('<div class="link-back">' + link_to('Back', :back) + '</div>')
  end
  

  #TODO: this ought to be rethought
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

          if @files
            parts << link_to("Files", submission_files_path(@submission))
          end
        elsif @solution
          parts << link_to('Suggested solution', exercise_solution_path(@exercise))
        end
        
      elsif @submission && !@submission.new_record?
        parts << raw("(deleted exercise #{breadcrumb_resource(@submission.exercise_name)})")
        parts << link_to(raw("Submission #{breadcrumb_resource('#' + @submission.id.to_s)}"), submission_path(@submission))

        if @files
          parts << link_to("Files", submission_files_path(@submission))
        end
      elsif action == 'submissions#index'
        parts << link_to("Submissions", course_submissions_path(@course))
      elsif action.start_with? 'feedback_questions'
        parts << link_to("Feedback questions", course_feedback_questions_path(@course))
      end
    elsif @user
      if @user.new_record?
        parts << link_to("Sign up", new_user_path)
      else
        parts << link_to("User account", user_path)
      end
    end

    if action == 'feedback_answers#index'
      parts << link_to("Feedback answers")
    end

    raw(parts.join(' &raquo; '))
  end
  
private
  def breadcrumb_resource(name)
    content_tag(:span, h(name), :class => 'breadcrumb-resource')
  end
end
