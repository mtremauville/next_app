class PasswordComplexityValidator < ActiveModel::EachValidator
  RULES = {
    lowercase: /[[:lower:]]/,
    uppercase: /[[:upper:]]/,
    digit: /\d/,
    special: /[^[:alnum:]\s]/
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    RULES.each do |rule, pattern|
      record.errors.add(attribute, :"password_#{rule}") unless value.match?(pattern)
    end
  end
end
