# typed: strict
# frozen_string_literal: true

# Prepares values for CSV exports that teachers open in spreadsheet programs.
module CsvCell
  extend T::Sig

  FORMULA_START = T.let(/\A[=+\-@\t\r]/, Regexp)

  # The value, prefixed with ' when it is a string a spreadsheet would evaluate as a formula.
  sig { params(value: T.untyped).returns(T.untyped) }
  def self.escape(value)
    value.is_a?(String) && value.match?(FORMULA_START) ? "'#{value}" : value
  end
end
