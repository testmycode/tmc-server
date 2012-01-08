module ApplicationHelper
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
    
    parts << link_to('Courses', courses_path)
    
    if @course && !@course.new_record?
      parts << link_to(@course.name, @course)
      
      if @exercise && !@exercise.new_record? && @exercise.course == @course
        parts << link_to(@exercise.name, course_exercise_path(@course, @exercise))
        
        if @submission && !@submission.new_record? && @submission.exercise == @exercise
          parts << link_to("Submission ##{@submission.id}", submission_path(@submission))
        elsif @solution
          parts << link_to('Suggested solution', course_exercise_solution_path(@course, @exercise))
        end
        
      elsif @submission && !@submission.new_record?
        parts << "(deleted exercise #{@submission.exercise_name})"
        parts << link_to("Submission ##{@submission.id}", submission_path(@submission))
      end
    end
    raw(parts.join(' &raquo; '))
  end
end
