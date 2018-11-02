require "unparser"
require "set"

# Rewrite Zombies with their idiomatic replacements
class EagerRewriter < Parser::TreeRewriter
  OPS = Parser::AST::Node.new(:const, [nil, :Ops])

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

  def s(name, *children)
    Parser::AST::Node.new(name, children)
  end

  def replace_node(old_node, new_node)
    source_range = old_node.loc.expression
    replace(source_range, Unparser.unparse(new_node))
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
