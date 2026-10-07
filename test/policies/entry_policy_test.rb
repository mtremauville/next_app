require "test_helper"

class EntryPolicyTest < ActiveSupport::TestCase
  test "owner can edit, update and destroy" do
    policy = EntryPolicy.new(users(:one), entries(:inception))
    assert policy.edit?
    assert policy.update?
    assert policy.destroy?
  end

  test "another user cannot" do
    policy = EntryPolicy.new(users(:two), entries(:inception))
    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns only own entries" do
    scope = EntryPolicy::Scope.new(users(:one), Entry).resolve
    assert_includes scope, entries(:inception)
    assert_not_includes scope, entries(:other_entry)
  end
end
