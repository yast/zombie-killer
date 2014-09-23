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
    n_receiver && n_receiver.type == :const &&
      n_receiver.children[0] == nil &&
      n_receiver.children[1] == namespace &&
      n_message == message
  end

  def nice(node)
    nice_literal(node) || nice_variable(node) || nice_send(node)
  end

  def nice_literal(node)
    node.type == :str
  end

  def nice_variable(node)
    node.type == :lvar && scope[node.children.first]
  end

  def nice_send(node)
    return false unless node.type == :send
    receiver, message, *args = *node

    receiver.nil? && message == :_ && args.size == 1 && nice(args.first)
  end

  def replace_node(old_node, new_node)
    replace(old_node.loc.expression, Unparser.unparse(new_node))
  end
end

class ZombieKiller
  # @returns new string
  def kill_string(code)
    buffer = Parser::Source::Buffer.new("(inline code)")
    buffer.source = code

    kill_buffer(buffer)
  end
  alias_method :kill, :kill_string

  # @param new_filename may be the same as *filename*
  def kill_file(filename, new_filename)
    buffer = Parser::Source::Buffer.new(filename)
    buffer.read

    new_string = kill_buffer(buffer)

    File.write(new_filename, new_string)
  end

  private

  # @returns String
  def kill_buffer(buffer)
    parser = Parser::CurrentRuby.new
    rewriter = ZombieKillerRewriter.new

    rewriter.rewrite(buffer, parser.parse(buffer))
  end
end
