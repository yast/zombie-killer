require "parser"
require "parser/current"
require "set"
require "unparser"

require_relative "niceness"
require_relative "variable_scope"

# We have encountered code that does satisfy our simplifying assumptions,
# translating it would not be correct.
class TooComplexToTranslateError < RuntimeError
end

# An error related to a node
class NodeError < RuntimeError
  attr_reader :node

  def initialize(message, node)
    @node = node
    super(message)
  end
end

# The main rewriter
class ZombieKillerRewriter < Parser::Rewriter
  include Niceness

  attr_reader :scopes

  def initialize(unsafe: false)
    @scopes = VariableScopeStack.new
    @unsafe = unsafe
  end

  def warning(message)
    $stderr.puts message if $VERBOSE
  end

  def rewrite(buffer, ast)
    super
  rescue TooComplexToTranslateError
    warning "(outer scope) is too complex to translate"
    buffer.source
  end

  # FIXME
  # How can we ensure that code modifications do not make some unhandled again?
  HANDLED_NODE_TYPES = [
    :alias,                     # Method alias
    :and,                       # &&
    :and_asgn,                  # &&=
    :arg,                       # One argument
    :args,                      # All arguments
    :back_ref,                  # Regexp backreference, $`; $&; $'
    :begin,                     # A simple sequence
    :block,                     # A closure, not just any scope
    :block_pass,                # Pass &foo as an arg which is a block, &:foo
    :blockarg,                  # An argument initialized with a block def m(&b)
    :break,                     # Break statement
    :case,                      # Case statement
    :casgn,                     # Constant assignment/definition
    :cbase,                     # Base/root of constant tree, ::Foo
    :class,                     # Class body
    :cvar,                      # Class @@variable
    :cvasgn,                    # Class @@variable = assignment
    :const,                     # Name of a class/module or name of a value
    :def,                       # Method definition
    :defined?,                  # defined? statement
    :defs,                      # Method definition on self
    :ensure,                    # Exception ensuring
    :for,                       # For v in enum;
    :gvar,                      # Global $variable
    :gvasgn,                    # Global $variable = assignment
    :if,                        # If and Unless
    :ivar,                      # Instance variable value
    :ivasgn,                    # Instance variable assignment
    :kwarg,                     # Keyword argument, def m(a:)
    :kwbegin,                   # A variant of begin; for rescue and while_post
    :kwoptarg,                  # Keyword optional argument, def m(a: 1)
    :kwrestarg,                 # Rest of keyword arguments, def m(**kwargs)
    :kwsplat,                   # Hash **splatting
    :lvar,                      # Local variable value
    :lvasgn,                    # Local variable assignment
    :match_with_lvasgn,         # /regex/ =~ value
    :masgn,                     # Multiple assigment: a, b = c, d
    :mlhs,                      # Left-hand side of a multiple assigment: a, b = c, d
    :module,                    # Module body
    :next,                      # Next statement
    :nil,                       # nil literal
    :nth_ref,                   # Regexp back references: $1, $2...
    :op_asgn,                   # a %= b where % is any operator except || &&
    :optarg,                    # Optional argument
    :or,                        # ||
    :or_asgn,                   # ||=
    :postexe,                   # END { }
    :regopt,                    # options tacked on a :regexp
    :resbody,                   # One rescue clause in a :rescue construct
    :rescue,                    # Groups the begin and :resbody
    :restarg,                   # Rest of arguments, (..., *args)
    :retry,                     # Retry a begin-rescue block
    :return,                    # Method return
    :sclass,                    # Singleton class, class << foo
    :send,                      # Send a message AKA Call a method
    :splat,                     # Array *splatting
    :super,                     # Call the ancestor method
    :unless,                    # Unless AKA If-Not
    :until,                     # Until AKA While-Not
    :until_post,                # Until with post-condtion
    :when,                      # When branch of an Case statement
    :while,                     # While loop
    :while_post,                # While loop with post-condition
    :xstr,                      # Executed `string`, backticks
    :yield,                     # Call the unnamed block
    :zsuper                     # Zero argument :super
  ].to_set + NICE_LITERAL_NODE_TYPES

  def process(node)
    return if node.nil?
    unless @unsafe
      raise NodeError.new("Unknown node type #{node.type}", node) unless
        HANDLED_NODE_TYPES.include? node.type
    end
    super
  end

  # currently visible scope
  def scope
    scopes.innermost
  end

  def with_new_scope_rescuing_oops(&block)
    scopes.with_new do
      block.call
    end
  rescue NodeError => e
    puts e
    puts "Node exception @ #{e.node.loc.expression}"
    puts "Offending node: #{e.node.inspect}"
  end

  def on_def(node)
    with_new_scope_rescuing_oops { super }
  end

  def on_defs(node)
    with_new_scope_rescuing_oops { super }
  end

  def on_module(node)
    with_new_scope_rescuing_oops { super }
  end

  def on_class(node)
    with_new_scope_rescuing_oops { super }
  end

  def on_sclass(node)
    with_new_scope_rescuing_oops { super }
  end

  def on_if(node)
    cond, then_body, else_body = *node
    process(cond)

    scopes.with_copy do
      process(then_body)
    end

    scopes.with_copy do
      process(else_body)
    end

    # clean slate
    scope.clear
  end

  # def on_unless
    # Does not exist.
    # `unless` is parsed as an `if` with then_body and else_body swapped.
    # Compare with `while` and `until` which cannot do that and thus need
    # distinct node types.
  # end

  def on_case(node)
    expr, *cases = *node
    process(expr)

    cases.each do |case_|
      scopes.with_copy do
        process(case_)
      end
    end

    # clean slate
    scope.clear
  end

  def on_lvasgn(node)
    super
    name, value = * node
    return if value.nil? # and-asgn, or-asgn, resbody do this
    scope[name].nice = nice(value)
  end

  def on_and_asgn(node)
    super
    var, value = * node
    return if var.type != :lvasgn
    name = var.children[0]

    scope[name].nice &&= nice(value)
  end

  def on_or_asgn(node)
    super
    var, value = * node
    return if var.type != :lvasgn
    name = var.children[0]

    scope[name].nice ||= nice(value)
  end

  def on_send(node)
    super
    if is_call(node, :Ops, :add)
      new_op = :+

      _ops, _add, a, b = *node
      if nice(a) && nice(b)
        replace_node node, Parser::AST::Node.new(:send, [a, new_op, b])
      end
    end
  end

  def on_block(node)
    # ignore body, clean slate
    scope.clear
  end
  alias_method :on_for, :on_block

  def on_while(node)
    # ignore both condition and body,
    # with a simplistic scope we cannot handle them

    # clean slate
    scope.clear
  end
  alias_method :on_until, :on_while

  # Exceptions:
  # `raise` is an ordinary :send for the parser

  def on_rescue(node)
    # (:rescue, begin-block, resbody..., else-block-or-nil)
    begin_body, *rescue_bodies, else_body = *node

    @source_rewriter.transaction do
      process(begin_body)
      process(else_body)
      rescue_bodies.each do |r|
        process(r)
      end
    end
  rescue TooComplexToTranslateError
    warning "begin-rescue is too complex to translate due to a retry"
  end

  def on_resbody(node)
    # How it is parsed:
    # (:resbody, exception-types-or-nil, exception-variable-or-nil, body)
    # exception-types is an :array
    # exception-variable is a (:lvasgn, name), without a value

    # A rescue means that *some* previous code was skipped. We know nothing.
    # We could process the resbodies individually,
    # and join begin-block with else-block, but it is little worth
    # because they will contain few zombies.
    scope.clear
    super
  end

  def on_ensure(node)
    # (:ensure, guarded-code, ensuring-code)
    # guarded-code may be a :rescue or not

    scope.clear
  end

  def on_retry(node)
    # that makes the :rescue a loop, top-down data-flow fails
    raise TooComplexToTranslateError
  end

  private

  def is_call(node, namespace, message)
    n_receiver, n_message = *node
    n_receiver && n_receiver.type == :const &&
      n_receiver.children[0] == nil &&
      n_receiver.children[1] == namespace &&
      n_message == message
  end

  def replace_node(old_node, new_node)
    source_range = old_node.loc.expression
    if !contains_comment?(source_range.source)
      replace(source_range, Unparser.unparse(new_node))
    end
  end

  def contains_comment?(string)
    /^[^'"\n]*#/.match(string)
  end
end
