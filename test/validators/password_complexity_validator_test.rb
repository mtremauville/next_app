require "test_helper"

class PasswordComplexityValidatorTest < ActiveSupport::TestCase
  def user_with(password)
    User.new(email: "nouveau@example.com", password: password, password_confirmation: password)
  end

  def error_types_for(password)
    user = user_with(password)
    user.valid?
    user.errors.where(:password).map(&:type)
  end

  test "a password with every category is accepted" do
    assert user_with("Passw0rd!2026").valid?
  end

  test "accented letters count as letters" do
    assert user_with("Éléphant9!rose").valid?
  end

  test "each missing category is reported" do
    assert_includes error_types_for("PASSW0RD!2026"), :password_lowercase
    assert_includes error_types_for("passw0rd!2026"), :password_uppercase
    assert_includes error_types_for("Password!abcd"), :password_digit
    assert_includes error_types_for("Passw0rd2026a"), :password_special
  end

  test "several problems are reported at once" do
    types = error_types_for("abcdefghij")

    assert_includes types, :password_uppercase
    assert_includes types, :password_digit
    assert_includes types, :password_special
  end

  test "a password shorter than 8 characters is refused" do
    assert_includes error_types_for("Aa1!"), :too_short
  end

  test "a password of exactly 8 characters is accepted" do
    assert user_with("Aa1!aaaa").valid?
  end

  test "a password longer than 72 characters is refused" do
    assert_includes error_types_for("Aa1!" + "a" * 70), :too_long
  end

  test "a space is not a special character" do
    assert_includes error_types_for("Passw0rd 2026"), :password_special
  end

  test "an existing account is not revalidated until its password changes" do
    user = users(:one)

    assert user.valid?

    user.password = "weak"
    user.password_confirmation = "weak"

    assert_not user.valid?
  end
end
