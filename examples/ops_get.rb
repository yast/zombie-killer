# frozen_string_literal: true

# unconditionally rewrite a generic form
require "yast"
module Yast
  def foo
    @var = Ops.get(object, index, default)
  end
end
