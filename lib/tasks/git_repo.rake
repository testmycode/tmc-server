namespace :course_repo do
  desc "check if course repository is valid"
  task :validate, :directory, :needs => :environment do |t, args|
    if GitBackend.valid_course_repository? args[:directory]
      FileUtils.touch "#{args[:directory]}/valid_course_repository"
    end
  end
end
