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
  Arg = Rule::Arg

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
    [:+, :-, :*].each do |asop|
      r from: s(xvasgn,
                Arg,
                s(:send, s(xvar, Arg), asop, Arg)), # @ARG1 = @ARG2 + ARG3
        to:   ->(a, b, c) do
          if a == b
            s(:op_asgn, s(xvasgn, a), asop, c) # @ARG1 += ARG3
          end
        end
    end
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
    r from: s(:send, OPS, prefix, Arg, Arg),   # Ops.add(Arg, ARG2)
      to:   ->(a, b) { s(:send, a, infix, b) } # Arg + ARG2
  end

  r from: s(:send, BUILTINS, :size, Arg), # Builtins.size(Arg)
    to:   ->(a) { s(:send, a, :size) }    # Arg.size

  r from: s(:send, s(:send, Arg, :size), :>, s(:int, 0)), # Arg.size > 0
    to:   ->(a) { s(:send, s(:send, a, :empty?), :!) } # !Arg.empty?

  r from: s(:send, s(:send, Arg, :size), :!=, s(:int, 0)), # Arg.size != 0
    to:   ->(a) { s(:send, s(:send, a, :empty?), :!) } # !Arg.empty?

  r from: s(:send, s(:send, Arg, :size), :==, s(:int, 0)), # Arg.size == 0
    to:   ->(a) { s(:send, a, :empty?) } # Arg.empty?

  r from: s(:send, s(:send, Arg, :size), :<=, s(:int, 0)), # Arg.size <= 0
    to:   ->(a) { s(:send, a, :empty?) } # Arg.empty?

  r from: s(:send, s(:send, Arg, :size), :<, s(:int, 1)), # Arg.size < 1
    to:   ->(a) { s(:send, a, :empty?) } # Arg.empty?

  def self.sformat_replacement1(format_literal, value)
    verbatims = format_literal.split("%1", -1)
    return nil unless verbatims.size == 2
    s(:dstr, s(:str, verbatims[0]), value, s(:str, verbatims[1]))
  end

  r from: s(:send, BUILTINS, :sformat, s(:str, Arg), Arg), # Builtins.sformat("...", val)
    to:   ->(fmt, val) { sformat_replacement1(fmt, val) }

  r from: s(:send, BUILTINS, :foreach, Arg),
    to:   ->(a) { s(:send, a, :each) }

  def unparser_sanitize(code_s)
    # unparser converts "foo#{bar}baz"
    # into "#{"foo"}#{bar}#{"baz"}"
    # so this undoes the escaping of the litetrals
    code_s.gsub(/
                  \#
                  \{"
                  (
                  [^"#]*
                  )
                  "\}
                /x,
                '\1')
  end

  def replace_node(old_node, new_node)
    # puts "OLD #{old_node.inspect}"
    # puts "NEW #{new_node.inspect}"
    source_range = old_node.loc.expression
    unp = Unparser.unparse(new_node)
    unp = unparser_sanitize(unp)
    # puts "UNP #{unp.inspect}"
    replace(source_range, unp)
    new_node
  end

  def process(node)
    node = super(node)
    return if node.nil?
    trules = self.class.rules.fetch(node.type, [])
    trules.find do |r|
      replacement = r.match(node)
      node = replace_node(node, replacement) if replacement
    end
    node
  end
end
