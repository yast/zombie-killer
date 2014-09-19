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
#    pp node
#    pp node.loc if node.respond_to? :loc
  end

  def initialize(*args)
    @@rewriting = 0
    super(*args)
  end

  def on_send(node)
    count = 0
    if node.receiver_is?(:Ops) && node.message.to_s.start_with?("get")
      node.children.each_with_index do |child_node, i|
#        printf "%02d %s ", i, child_node.class
#        dump child_node
#        puts
      end

      $stderr.puts node.inspect
      object  = node.children[2]
#      $stderr.puts object.inspect
      index   = node.children[3]
      default = node.children[4]
      if default != nil
        if @@rewriting > 0
          $stderr.puts "REWRITING ALREADY"
        else
          count = 1
          @@rewriting += count
          fetch = Parser::AST::Node.new(:send, [object, :fetch, index, default])

          $stderr.puts "REWRITTEN:"
          $stderr.puts fetch.inspect

          replace(node.loc.expression, Unparser.unparse(fetch))
        end
      end
    end

    super
    @@rewriting -= count
  end
end
