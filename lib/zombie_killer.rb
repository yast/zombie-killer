require "parser"
require "parser/current"
require "unparser"

# Tracks niceness for local variables visible at certain point
class VariableScope < Hash
  # @return [Boolean] nice
  def [](varname)
    super
  end

  # Set niceness for a variable
  def []=(varname, nice)
    super
  end
end

class ZombieKillerRewriter < Parser::Rewriter
  def initialize
    outer_scope = VariableScope.new
    @scopes = [outer_scope]
  end

  # currently visible scope
  def scope
    @scopes.last
  end

  def on_def(node)
    @scopes.push VariableScope.new
    super
    @scopes.pop
  end

  # local(?) variable assignment
  def on_vasgn(node)
    name, value = * node
    scope[name] = nice(value)
  end

  def on_send(node)
    if is_call(node, :Ops, :add)
      new_op = :+

      ops, add, a, b = *node
      if nice(a) && nice(b)
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

  def nice(node)
    nice_literal(node) || nice_variable(node)
  end

  def nice_literal(node)
    node.type == :str
  end

  def nice_variable(node)
    node.type == :lvar && scope[node.children.first]
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
