# frozen_string_literal: true

class Api::Beta::StatsController < Api::Beta::BaseController
  before_action :doorkeeper_authorize!, scopes: [:public]

  def submission_processing_times
    processing_began_at = Submission.arel_table[:processing_began_at]
    results = Submission
              .select("COUNT(id), extract(epoch from avg(processing_completed_at - processing_began_at)) as avg_duration, stddev_samp(extract(epoch from processing_completed_at - processing_began_at)) as stddev, date_trunc('minute', processing_began_at) as minute")
              .where.not(processing_began_at: nil)
              .where(processing_began_at.gteq(1.month.ago))
              .group("date_trunc('minute', processing_began_at)")
              .order("date_trunc('minute', processing_began_at) DESC")

    res = results.map do |result|
      {
        avg_duration: result.avg_duration,
        stddev: result.stddev,
        minute: result.minute,
        count: result.count
      }
    end
    present(res)
  end

  def submission_queue_times
    created_at = Submission.arel_table[:created_at]
    results = Submission
              .select("COUNT(id), extract(epoch from avg(processing_began_at - created_at)) as avg_duration,  stddev_samp(extract(epoch from processing_completed_at - processing_began_at)) as stddev, date_trunc('minute', created_at) as minute") .where.not(processing_began_at: nil) .where(created_at.gteq(1.month.ago)) .group("date_trunc('minute', created_at)") .order("date_trunc('minute', created_at) DESC")

    res = results.map do |result|
      {
        avg_duration: result.avg_duration,
        stddev: result.stddev,
        minute: result.minute,
        count: result.count
      }
    end
    present(res)
  end
end
