# typed: strict
# frozen_string_literal: true

# The tasks script/background_daemon runs: every class in app/background_tasks, each responding to run and wait_delay.
module BackgroundTaskRegistry
  extend T::Sig

  sig { params(cls: T::Class[Object]).void }
  def self.register(cls)
    classes << cls
  end

  sig { returns(T::Array[T::Class[Object]]) }
  def self.classes
    @classes ||= T.let([], T.nilable(T::Array[T::Class[Object]]))
  end

  sig { returns(T::Array[Object]) }
  def self.all_tasks
    @instances ||= T.let(classes.map(&:new), T.nilable(T::Array[Object]))
  end
end

Dir.glob(Rails.root.to_s + '/app/background_tasks/*.rb').each do |f|
  BackgroundTaskRegistry.register File.basename(f, '.rb').classify.constantize
end
