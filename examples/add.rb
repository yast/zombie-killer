# frozen_string_literal: true

def condition_checks_value_is_not_nil(s)
  Ops.add(s, "foo") unless s.nil?
end
