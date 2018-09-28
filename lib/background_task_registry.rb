# frozen_string_literal: true

module BackgroundTaskRegistry
  def self.register(cls)
    classes << cls
  end

  def self.classes
    @classes ||= []
  end

  def self.all_tasks
    @instances ||= classes.map(&:new)
  end
end

Dir.glob(Rails.root.to_s + '/app/background_tasks/*.rb').each do |f|
  BackgroundTaskRegistry.register File.basename(f, '.rb').classify.constantize
end
