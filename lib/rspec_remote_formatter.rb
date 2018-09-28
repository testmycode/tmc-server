# frozen_string_literal: true

require 'net/http'
require 'json'

class RspecRemoteFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending

  def initialize(output); end

  # One of these per example, depending on outcome
  # ExampleNotification
  def example_passed(notification)
    post(__method__, notification_to_document(notification))
  end

  def host
    @host ||= ENV.fetch('HOST') { `hostname`.chomp }
  end

  # FailedExampleNotification
  def example_failed(notification)
    post(__method__, notification_to_document(notification))
  end

  def example_pending(notification)
    post(__method__, notification_to_document(notification))
  end

  def notification_to_document(notification)
    metadata = notification.example.metadata
    ex_res = metadata[:execution_result]
    {
      host: host,
      full_description: metadata[:full_description],
      status: ex_res.status,
      file_path: metadata[:file_path],
      line_number: metadata[:line_number],
      exception: notification.example.exception.to_s || ex_res.exception.to_s,
      started_at: ex_res.started_at,
      finished_at: ex_res.finished_at,
      run_time: ex_res.run_time.to_s
    }
  end

  def post(rspec_method, data)
    host = ENV.fetch('REPORT_URL')
    port = ENV.fetch('REPORT_PORT')
    http = Net::HTTP.new(host, port)
    http.post("/#{rspec_method}.json", data.to_json)
  end
end
