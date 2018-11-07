# frozen_string_literal: true

# Tracks state for a variable
class VariableState
  attr_accessor :nice
end

# Tracks state for local variables visible at certain point.
# Keys are symbols, values are VariableState
class VariableScope < Hash
  def initialize
    super do |hash, key|
      hash[key] = VariableState.new
    end
  end

  # Deep copy the VariableState values
  def dup
    copy = self.class.new
    each do |k, v|
      copy[k] = v.dup
    end
    copy
  end

  # @return [VariableState] state
  def [](varname)
    super
  end

  # Set state for a variable
  def []=(varname, state)
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
