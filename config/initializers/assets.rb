# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( application-bare.css application-bare.js application-test.css courses.js solutions.css solutions.js submissions.css submissions.js reviews.css reviews.js migrate_to_other_course.css migrate_to_other_course.js)

# Include vendor images
Rails.application.config.assets.precompile << proc do |path|
  full_path = Rails.application.assets.resolve(path).to_s
  full_path.include?('vendor/assets/images/')
end
