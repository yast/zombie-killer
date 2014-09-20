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
      if node.receiver_is?(:Ops) && node.message.to_s.start_with?("get")
        if replace_ops_get(node)
          count = 1
        end
      elsif node.receiver_is?(:Ops) && node.message == :add
      end
    end

    @@rewriting += count
    super
    @@rewriting -= count
  end

  # @returns true if did replacement
  def replace_ops_get(node)
    $stderr.puts node.inspect

    receiver, message, object, index, default = * node
    return false if default.nil?
    fetch = Parser::AST::Node.new(:send, [object, :fetch, index, default])

    $stderr.puts "REWRITTEN:"
    $stderr.puts fetch.inspect

    replace(node.loc.expression, Unparser.unparse(fetch))
    true
  end
end
