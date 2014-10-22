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

# A stack of VariableScope
class VariableScopeStack
  def initialize
    outer_scope = VariableScope.new
    @stack = [outer_scope]
  end

  # The innermost, or current VariableScope
  def innermost
    @stack.last
  end

  # Run *block* using a new clean scope
  # @return the scope as the block left it, popped from the stack
  def with_new(&block)
    @stack.push VariableScope.new
    block.call
    @stack.pop
  end

  # Run *block* using a copy of the innermost scope
  # @return the scope as the block left it, popped from the stack
  def with_copy(&block)
    @stack.push innermost.dup
    block.call
    @stack.pop
  end
end
