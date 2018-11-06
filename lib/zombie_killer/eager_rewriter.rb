require "unparser"
require "set"

require "zombie_killer/rule"

# Rewrite Zombies with their idiomatic replacements
class EagerRewriter < Parser::TreeRewriter
  def self.s(name, *children)
    Parser::AST::Node.new(name, children)
  end

  def s(name, *children)
    self.class.s(name, *children)
  end

  OPS = s(:const, nil, :Ops)
  BUILTINS = s(:const, nil, :Builtins)

  @rules = {}
  class << self
    attr_reader :rules
  end

  def self.r(**kwargs)
    rule = Rule.new(**kwargs)
    type = rule.from.type
    @rules[type] ||= []
    @rules[type] << rule
  end

  [
    [:lvasgn, :lvar],           # a = b
    [:ivasgn, :ivar],           # @a = @b
    [:cvasgn, :cvar],           # @@a = @@b
  ].each do |xvasgn, xvar|
    r from: s(xvasgn,
              ARG1,
              s(:send, s(xvar, ARG2), :+, ARG3)), # @ARG1 = @ARG2 + ARG3
      cond: ->(a, b, _c) { a == b },
      to:   s(:op_asgn, s(xvasgn, ARG1), :+, ARG3) # @ARG1 += ARG3
  end

  INFIX = {
    add: :+,
    subtract: :-,
    multiply: :*,
    divide: :/,
    modulo: :%,
    bitwise_and: :&,
    bitwise_or: :|,
    bitwise_xor: :^,

    less_than: :<,
    less_or_equal: :<=,
    greater_than: :>,
    greater_or_equal: :>=
  }.freeze

  INFIX.each do |prefix, infix|
    r from: s(:send, OPS, prefix, ARG1, ARG2), # Ops.add(ARG1, ARG2)
      to:   s(:send, ARG1, infix, ARG2)        # ARG1 + ARG2
  end

  r from: s(:send, s(:send, BUILTINS, :size, ARG1), :>, s(:int, 0)), # Builtins.size(ARG1) > 0
    to:   s(:send, s(:send, ARG1, :empty?), :!) # !ARG1.empty?

  r from: s(:send, s(:send, BUILTINS, :size, ARG1), :==, s(:int, 0)), # Builtins.size(ARG1) == 0
    to:   s(:send, ARG1, :empty?) # ARG1.empty?

  r from: s(:send, s(:send, BUILTINS, :size, ARG1), :<, s(:int, 1)), # Builtins.size(ARG1) < 1
    to:   s(:send, ARG1, :empty?) # ARG1.empty?

  # FIXME!
  @rules = {}
  r from: s(:send, BUILTINS, :size, ARG1), # Builtins.size(ARG1)
    to:   s(:send, ARG1, :size)            # ARG1.size

  def replace_node(old_node, new_node)
    source_range = old_node.loc.expression
    replace(source_range, Unparser.unparse(new_node))
  end

  def process(node)
    return if node.nil?
    trules = self.class.rules.fetch(node.type, [])
    trules.each do |r|
      replacement = r.match(node)
      replace_node(node, replacement) if replacement
    end
    super
  end

  def on_send(node)
    super
    receiver, name, *args = *node
    replacement = INFIX[name]
    if receiver == OPS && replacement && args.size == 2
      replace_node(node, s(:send, args[0], replacement, args[1]))
    end
  end

  AS_OPS = Set.new [:+, :-]
  def on_lvasgn(node)
    super
    vname1, value = *node
    return unless value && value.type == :send
    receiver, oname, *args = *value
    if vname1 == lvar_vname2(receiver) && AS_OPS.include?(oname)
      replace_node(node, s(:op_asgn, s(:lvasgn, vname1), oname, args[0]))
    end
  end

  def lvar_vname2(receiver)
    receiver.children.first if receiver && receiver.type == :lvar
  end
end
