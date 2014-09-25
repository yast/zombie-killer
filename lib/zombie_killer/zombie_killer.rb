require "parser"
require "parser/current"
require "set"
require "unparser"

require_relative "version"

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


# We have encountered code that does satisfy our simplifying assumptions,
# translating it would not be correct.
class TooComplexToTranslateError < Exception
end

class ZombieKillerRewriter < Parser::Rewriter
  def initialize(unsafe: false)
    outer_scope = VariableScope.new
    @scopes = [outer_scope]
    @unsafe = unsafe
  end

  def rewrite(buffer, ast)
    super
  rescue TooComplexToTranslateError
    puts "Outer scope is too complex to translate, sorry"
    buffer.source
  end

  # Literals are nice, except the nil literal.
  NICE_LITERAL_NODE_TYPES = [:false, :int, :self, :str, :sym, :true].to_set

  # FIXME
  # How can we ensure that code modifications do not make some unhandled again?
  HANDLED_NODE_TYPES = [
    :arg,                       # One argument
    :args,                      # All arguments
    :begin,                     # A simple sequence
    :const,         # FIXME a constant could be defined to be nil
    :def,                       # Method definition
    :lvar,                      # Local variable value
    :lvasgn,                    # Local variable assignment
    :nil,                       # nil literal
    :send,                      # Send a message AKA Call a method
    :while                      # TooComplexToTranslateError
  ].to_set + NICE_LITERAL_NODE_TYPES

  def process(node)
    return if node.nil?
    if ! @unsafe
      oops(node, RuntimeError.new("Unknown node type #{node.type}")) unless
        HANDLED_NODE_TYPES.include? node.type
    end
    super
  end

  # currently visible scope
  def scope
    @scopes.last
  end

  def on_def(node)
    @scopes.push VariableScope.new
    super
    @scopes.pop
  rescue TooComplexToTranslateError
    name = node.children.first
    puts "def #{name} is too complex to translate, sorry"
  rescue => e
    oops(node, e)
  end

  def on_if(node)
    # FIXME need separate scopes for the branches
    super
  end

  # local(?) variable assignment
  def on_vasgn(node)
    super
    name, value = * node
    return if value.nil? # and-asgn, or-asgn do this
    scope[name] = nice(value)
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
  end

  def on_while(node)
    raise TooComplexToTranslateError
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
    NICE_LITERAL_NODE_TYPES.include? node.type
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
    source_range = old_node.loc.expression
    if !contains_comment?(source_range.source)
      replace(source_range, Unparser.unparse(new_node))
    end
  end

  def contains_comment?(string)
    ret = /^[^'"\n]*#/.match(string)
  end
end

class ZombieKiller
  # @returns new string
  def kill_string(code, filename = "(inline code)", unsafe: false)
    fixed_point(code) do |code|
      parser   = Parser::CurrentRuby.new
      rewriter = ZombieKillerRewriter.new(unsafe: unsafe)
      buffer   = Parser::Source::Buffer.new(filename)
      buffer.source = code
      rewriter.rewrite(buffer, parser.parse(buffer))
    end
  end
  alias_method :kill, :kill_string

  # @param new_filename may be the same as *filename*
  def kill_file(filename, new_filename, unsafe: false)
    new_string = kill_string(File.read(filename), filename, unsafe: unsafe)

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
