
# A node has two attributes:
# in-state
# out-state
# which map from local variables (including method and block arguments)
# to a set of nodes that may se the source of their value at that point.

# reopen parser.gem
class Parser::AST::Node
  # Modified sexp that also notes variables tracked in the state:
  # (type child child){v1 v2}
  def to_sexp(indent = 0)
    props = ""
    if @state
      props << "{" << @state.keys.sort.join(",") << "}"
    end
    super + props
  end
  alias_method :inspect, :to_sexp

  # Assign any properties, not just location
  def assign_properties(properties)
    super
  end
end

# reopen ast.gem
class AST::Node
  # Don't discard properties.
  # Rely on the inherited implementation instead.
  #
  # The problem surfaces in Parser::AST::Node.updated where it
  # considers the properties of the updated node but
  # neglects that children have been updated to add properties too.
  def ==(other)
    super
  end
end

class DataSourceAnnotator < Parser::AST::Processor
  def on_lvasgn(node)
    node = super
    name, value = *node

    state = Hash.new            # FIXME, get it from value (for v = w = 1)
    state[name] = value
    n = node.updated(nil, nil, { state: state })
    n
  end
end
