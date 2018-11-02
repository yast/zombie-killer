require "spec_helper"
require "zombie_killer/rule"

describe Rule do
  include AST::Sexp # the `s` method
  extend AST::Sexp

  BUILTINS = s(:const, nil, :Builtins)

  context "a simple const rule" do
    let(:rule) do
      Rule.new(
        from: s(:const, nil, :Round),
        to:   s(:lvar, :square)
      )
    end

    describe "#match" do
      it "matches what it should" do
        node = s(:const, nil, :Round)
        expect(!!rule.match(node)).to eq(true)
      end

      it "does not match nil" do
        expect(!!rule.match(nil)).to eq(false)
      end

      it "does not match a different const" do
        node = s(:const, nil, :Square)
        expect(!!rule.match(node)).to eq(false)
      end

      it "does not match a differently namespaced const" do
        node = s(:const, s(:const, nil, :Square), :Round)
        expect(!!rule.match(node)).to eq(false)
      end
    end
  end

  context "a capturing rule" do
    let(:rule) do
      Rule.new(
        from: s(:send, BUILTINS, :size, Rule::Arg), # Builtins.size(ARG1)
        to:   s(:send, Rule::Arg1, :size)           # ARG1.size
      )
    end

    describe "#match2" do
      it "returns the captured node" do
        node = s(:send, BUILTINS, :size, s(:send, nil, :foo))
        expect(rule.match2(rule.from, node)).to eq([s(:send, nil, :foo)])
      end
    end
  end
end
