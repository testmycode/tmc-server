# typed: strict
# frozen_string_literal: true

class FeedbackQuestion < ApplicationRecord
  extend T::Sig
  include Orderable

  belongs_to :course
  has_many :feedback_answers, dependent: :delete_all

  validates :course, presence: true
  validates :kind, presence: true
  validates :question, presence: true
  validate :validate_kind

  sig { returns(String) }
  def title_or_question
    title || question
  end

  sig { returns(T.nilable(Integer)) }
  def intrange?
    kind =~ intrange_regex
  end

  sig { returns(T::Range[Integer]) }
  def intrange
    if kind =~ intrange_regex
      (Regexp.last_match(1).to_i)..(Regexp.last_match(2).to_i)
    else
      raise 'not an intrange question'
    end
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def record_for_api
    {
      id: id,
      question: question,
      kind: kind
    }
  end

  private
    sig { returns(Regexp) }
    def intrange_regex
      self.class.intrange_regex
    end

    sig { returns(Regexp) }
    def self.intrange_regex
      /^intrange\[(-?\d+)\.\.(-?\d+)\]$/
    end

    sig { void }
    def validate_kind
      errors.add(:kind, 'invalid') unless kind == 'text' || kind =~ intrange_regex
    end
end
