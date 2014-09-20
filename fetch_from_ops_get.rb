# Rewrite Ops.get(object, index, default) to object.fetch(index, default)
# Usage:
#   ruby-rewrite2.0 -m -l fetch_from_ops_get.rb \
#     /usr/share/YaST2/modules/Storage.rb >  ~/tmp/Storage.rb
require "pp"
require "unparser"

# reopen
class Parser::AST::Node
  def receiver_is?(symbol)
    return false unless type == :send
    receiver = children.first
#    $stderr.puts receiver.inspect
    return false unless receiver.is_a? self.class
    receiver.type == :const &&
      receiver.children[0] == nil &&
      receiver.children[1] == symbol
  end

  def message
    return false unless type == :send
    children[1]
  end
end

REPLACERS = [
  [:Ops, /^get/, :replace_ops_get],
  [:Ops, :bitwise_not,   :replace_ops_bitwise_not],

]

BINARY_OPERATORS = {
  add:              :+,
  bitwise_and:      :&,
  bitwise_or:       :|,
  bitwise_xor:      :^,
  divide:           :/,
  greater_or_equal: :>=,
  greater_than:     :>,
  less_or_equal:    :<=,
  less_than:        :<,
  modulo:           :%,
  multiply:         :*,
  shift_left:       :<<,
  shift_right:      :>>,
  subtract:         :-,
}

class FetchFromOpsGet < Parser::Rewriter
  def dump(node)
    pp node
    pp node.loc if node.respond_to? :loc
  end

  def dump_children(node)
    node.children.each_with_index do |child_node, i|
      printf "%02d %s ", i, child_node.class
      dump child_node
      puts
    end
  end

  def initialize(*args)
    @@rewriting = 0
    super(*args)
  end

  def on_send(node)
    count = 0
    if @@rewriting == 0
      REPLACERS.find do |receiver, message, replacer|
        match = node.receiver_is?(receiver) && message === node.message
        if match
          if self.send(replacer, node)
            count = 1
          end
        end
        match
      end

      if node.receiver_is?(:Ops) && BINARY_OPERATORS.has_key?(node.message)
        replace_binary_operator(node)
        count = 1
      end
    end

    @@rewriting += count
    super
    @@rewriting -= count
  end

  # @returns true
  def replace_node(old_node, new_node)
#    $stderr.puts "REPLACING:"
#    $stderr.puts old_node.inspect

#    $stderr.puts "REWRITTEN:"
#    $stderr.puts new_node.inspect

    replace(old_node.loc.expression, Unparser.unparse(new_node))
    true
  end

  # @returns true if did replacement
  def replace_ops_get(node)
    ops, get, object, index, default = * node
    return false if default.nil?
    replace_node node, Parser::AST::Node.new(:send, [object, :fetch, index, default])
  end

  # @returns true if did replacement
  def replace_ops_bitwise_not(node)
    ops, op, a = * node
    replace_node node, Parser::AST::Node.new(:send, [a, :~])
  end

  # @returns true if did replacement
  def replace_binary_operator(node)
    ops, op, a, b = * node
    new_op = BINARY_OPERATORS[op]
    replace_node node, Parser::AST::Node.new(:send, [a, new_op, b])
  end

end
