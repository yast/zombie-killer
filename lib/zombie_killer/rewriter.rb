require "parser"
require "parser/current"
require "set"
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

  def warning(message)
    $stderr.puts message if $VERBOSE
  end

  def rewrite(buffer, ast)
    super
  rescue TooComplexToTranslateError
    warning "(outer scope) is too complex to translate"
    buffer.source
  end

  # Literals are nice, except the nil literal.
  NICE_LITERAL_NODE_TYPES = [
    :self,
    :false, :true,
    :int, :float,
    :str, :sym, :regexp,
    :array, :hash, :pair, :irange, # may contain nils but they are not nil
    :dstr,                      # "String #{interpolation}" mixes :str, :begin
    :dsym                       # :"#{foo}"
  ].to_set

  # FIXME
  # How can we ensure that code modifications do not make some unhandled again?
  HANDLED_NODE_TYPES = [
    :alias,                     # Method alias
    :and,                       # &&
    :arg,                       # One argument
    :args,                      # All arguments
    :back_ref,                  # Regexp backreference, $`; $&; $'
    :begin,                     # A simple sequence
    :block,                     # A closure, not just any scope
    :block_pass,                # Pass &foo as an arg which is a block, &:foo
    :blockarg,                  # An argument initialized with a block def m(&b)
    :casgn,                     # Constant assignment/definition
    :cbase,                     # Base/root of constant tree, ::Foo
    :class,                     # Class body
    :cvar,                      # Class @@variable
    :cvassgn,                   # Class @@variable = assignment
    :const,                     # Name of a class/module or name of a value
    :def,                       # Method definition
    :defs,                      # Method definition on self
    :ensure,                    # Exception ensuring
    :for,                       # For v in enum;
    :gvar,                      # Global $variable
    :gvassgn,                   # Global $variable = assignment
    :if,                        # If and Unless
    :ivar,                      # Instance variable value
    :ivasgn,                    # Instance variable assignment
    :kwbegin,                   # A variant of begin; for rescue and while_post
    :kwoptarg,                  # Keyword optional argument, def m(a: 1)
    :lvar,                      # Local variable value
    :lvasgn,                    # Local variable assignment
    :module,                    # Module body
    :nil,                       # nil literal
    :nth_ref,                   # Regexp back references: $1, $2...
    :op_asgn,                   # a %= b where % is any operator except || &&
    :optarg,                    # Optional argument
    :or,                        # ||
    :postexe,                   # END { }
    :regopt,                    # options tacked on a :regexp
    :resbody,                   # One rescue clause in a :rescue construct
    :rescue,                    # Groups the begin and :resbody
    :restarg,                   # Rest of arguments, (..., *args)
    :retry,                     # Retry a begin-rescue block
    :return,                    # Method return
    #:sclass,                    # Singleton class, class << foo
    :send,                      # Send a message AKA Call a method
    :splat,                     # Array *splatting
    :super,                     # Call the ancestor method
    :unless,                    # Unless AKA If-Not
    :until,                     # Until AKA While-Not
    :until_post,                # Until with post-condtion
    :while,                     # While loop
    :while_post,                # While loop with post-condition
    :xstr,                      # Executed `string`, backticks
    :yield,                     # Call the unnamed block
    :zsuper                     # Zero argument :super
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
    warning "def #{name} is too complex to translate"
  rescue => e
    oops(node, e)
  end
  alias_method :on_defs, :on_def

  def on_if(node)
    cond, then_body, else_body = *node
    process(cond)

    @scopes.push scope.dup
    process(then_body)
    @scopes.pop

    @scopes.push scope.dup
    process(else_body)
    @scopes.pop

    # clean slate
    scope.clear
  end

  # def on_unless
    # Does not exist.
    # `unless` is parsed as an `if` with then_body and else_body swapped.
    # Compare with `while` and `until` which cannot do that and thus need
    # distinct node types.
  # end

  # local(?) variable assignment
  def on_vasgn(node)
    super
    name, value = * node
    return if value.nil? # and-asgn, or-asgn, resbody do this
    scope[name] = nice(value)
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
    /^[^'"\n]*#/.match(string)
  end
end
