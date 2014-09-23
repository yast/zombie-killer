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

  def on_if(node)
    # FIXME need separate scopes for the branches
    super
  end

  # local(?) variable assignment
  def on_vasgn(node)
    super
    name, value = * node
    scope[name] = nice(value)
  rescue => e
    oops(node, e)
  end

  def on_send(node)
    super
    if is_call(node, :Ops, :add)
      new_op = :+

      ops, add, a, b = *node
      if nice(a) && nice(b)
        replace_node node, Parser::AST::Node.new(:send, [a, new_op, b])
      end
    end
  rescue => e
    oops(node, e)
  end

  private

  def oops(node, exception)
    puts "Node exception @ #{node.loc.expression}"
    puts "Offending node: #{node.inspect}"
    raise exception
  end

  def is_call(node, namespace, message)
    n_receiver, n_message = *node
    n_receiver && n_receiver.type == :const &&
      n_receiver.children[0] == nil &&
      n_receiver.children[1] == namespace &&
      n_message == message
  end

  def nice(node)
    nice_literal(node) || nice_variable(node) || nice_send(node) ||
      nice_begin(node)
  end

  def nice_literal(node)
    node.type == :str
  end

  def nice_variable(node)
    node.type == :lvar && scope[node.children.first]
  end

  # Methods that preserve niceness if all their arguments are nice
  # These are global, called with a nil receiver
  NICE_GLOBAL_METHODS = {
    # message, number of arguments
    :_ => 1,
  }.freeze

  NICE_OPERATORS = {
    # message, number of arguments (other than receiver)
    :+ => 1,
  }.freeze

  def nice_send(node)
    return false unless node.type == :send
    receiver, message, *args = *node

    if receiver.nil?
      arity = NICE_GLOBAL_METHODS.fetch(message, -1)
    else
      return false unless nice(receiver)
      arity = NICE_OPERATORS.fetch(message, -1)
    end
    return args.size == arity && args.all?{ |a| nice(a) }
  end

  def nice_begin(node)
    node.type == :begin && nice(node.children.last)
  end

  def replace_node(old_node, new_node)
    replace(old_node.loc.expression, Unparser.unparse(new_node))
  end
end

class ZombieKiller
  # @returns new string
  def kill_string(code, filename = "(inline code)")
    fixed_point(code) do |code|
      parser   = Parser::CurrentRuby.new
      rewriter = ZombieKillerRewriter.new
      buffer   = Parser::Source::Buffer.new(filename)
      buffer.source = code
      rewriter.rewrite(buffer, parser.parse(buffer))
    end
  end
  alias_method :kill, :kill_string

  # @param new_filename may be the same as *filename*
  def kill_file(filename, new_filename)
    new_string = kill_string(File.read(filename), filename)

    File.write(new_filename, new_string)
  end

  private

  def fixed_point(x, &lambda_x)
    while true
      y = lambda_x.call(x)
      return y if y == x
      x = y
    end
  end
end
