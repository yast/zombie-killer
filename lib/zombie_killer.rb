require "parser"
require "parser/current"
require "unparser"

class ZombieKillerRewriter < Parser::Rewriter
  def on_send(node)
    if is_call(node, :Ops, :add)
      new_op = :+

      ops, add, a, b = *node
      if nice_literal(a) && nice_literal(b)
        replace_node node, Parser::AST::Node.new(:send, [a, new_op, b])
      end
    end
  end

  private

  def is_call(node, namespace, message)
    n_receiver, n_message = *node
    n_receiver.type == :const &&
      n_receiver.children[0] == nil &&
      n_receiver.children[1] == namespace &&
      n_message == message
  end

  def nice_literal(node)
    node.type == :str
  end

  def replace_node(old_node, new_node)
    replace(old_node.loc.expression, Unparser.unparse(new_node))
  end
end

class ZombieKiller
  def kill(s)
    rewriter = ZombieKillerRewriter.new
    rewrite(s, rewriter)
  end

  private

  def rewrite(code, rewriter)
    buffer = Parser::Source::Buffer.new("(inline code)")
    buffer.source = code
    parser = Parser::CurrentRuby.new

    rewriter.rewrite(buffer, parser.parse(buffer))
  end
end
