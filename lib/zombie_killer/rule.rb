class ARG; end
class ARG1 < ARG; end
class ARG2 < ARG; end
class ARG3 < ARG; end

# Rewriting rule
class Rule
  Placeholder = Struct.new(:name) do
    def inspect
      name
    end
  end
  Arg = Placeholder.new("Arg")
  Arg1 = Placeholder.new("Arg1")

  # @return [AST::Node]
  attr_reader :from
  # @return [Proc]
  attr_reader :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def match(node)
    captures = match2(from, node)
    return unless captures
    if to.respond_to? :call
      to.call(*captures)
    else
      to
    end
  end

  # @return an array of captured values or nil
  def match2(expected, actual)
    #puts "M2 #{expected.inspect} #{actual.inspect}"
    #p expected.class
    #p actual.class
    return [] if expected.nil? && actual.nil?
    return nil if expected.nil? || actual.nil?

    # if we're a node
    case expected
    when AST::Node
      return nil if expected.type != actual.type
      return nil if expected.children.size != actual.children.size

      results = expected.children.zip(actual.children).map do |ec, ac|
        match2(ec, ac)
      end
      #puts "#{results.inspect} for #{expected.inspect}"
      if results.all?
        results.flatten(1)
      else
        nil
      end
    when Rule::Arg
      #puts "ARG #{actual.inspect}"
      [actual]
    else
      expected == actual ? [] : nil
    end
  end
end
