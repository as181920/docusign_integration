require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:audit_log), :valid?
  end

  test "requires action" do
    log = AuditLog.new

    assert_not log.valid?
    assert log.errors.of_kind?(:action, :blank)
  end
end
