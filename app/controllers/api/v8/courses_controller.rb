
class Api::V8::CoursesController < Api::V8::BaseController
  def show_json
    course = params[:id] && Course.find(params[:id]) || Course.find_by(name: "#{params[:slug]}-#{params[:name]}")
    present(course)
  end
end
