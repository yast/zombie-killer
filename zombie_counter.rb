# A Zombie is a call to Ops.* or Builtins.*,
# the wrappers defined in yast2-ruby-bindings
#
# Usage:
#   ruby-rewrite2.0 2>&1 >/dev/null-l zombie_counter.rb /usr/share/YaST2/modules/Storage.rb
#
# Output:
#
#   1 Builtins.tolower
#   2 Builtins.regexpsub
#   3 Builtins.regexppos
#...
# 119 Ops.add
# 148 Ops.get_symbol
# 229 Ops.set
# 256 Ops.get_string
# 338 Builtins.y2milestone
# 753 Ops.GET
#
# (Ops.GET is a sum over all flavors of Ops.get)

require "pp"
require_relative "./lib/code_histogram"

class ZombieCounter < Parser::Rewriter
  def initialize(*args)
    @@counts = CodeHistogram.new
    super(*args)
  end

  def on_send(node)
    count_zombies(node)
    super
  end

  def count_zombies(node)
    receiver, message = * node
    if receiver && receiver.type == :const && receiver.children[0] == nil
      modul = receiver.children[1]
      if [:Ops, :Builtins].include? modul
        method = "#{modul}.#{message}"
        @@counts.increment(method)
      end
    end
  end

  def self.aggregate_ops_get
    total = 0
    @@counts.counts.each do |method, count|
      total += count if method.start_with? "Ops.get"
    end
    @@counts.increment("Ops.GET", total)
  end

  def self.report
    aggregate_ops_get
    @@counts.print_by_frequency($stderr)
  end
end

# Dirty! This runs at the end of the program.
# It is easier than discovering how to reuse Rewriter properly.
END {
  ZombieCounter.report
}
