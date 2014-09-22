# A Zombie is a call to Ops.* or Builtins.*,
# the wrappers defined in yast2-ruby-bindings
#
require "pp"
require_relative "./lib/code_histogram"

class OpsAddCounter < Parser::Rewriter
  def initialize(*args)
    @@counts = CodeHistogram.new
    super(*args)
  end

  def on_send(node)
    count_zombies(node)
    super
  end

  def count_zombies(node)
    receiver, message, a, b = * node
    return unless receiver && receiver.type == :const &&
      receiver.children[0] == nil && receiver.children[1] == :Ops
    return unless message == :add
    types = [a.type, b.type].sort.to_s
    @@counts.increment(types)
  end

  def self.report
    @@counts.print_by_frequency($stderr)
  end
end

# Dirty! This runs at the end of the program.
# It is easier than discovering how to reuse Rewriter properly.
END {
  OpsAddCounter.report
}
