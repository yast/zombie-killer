require_relative "spec_helper"

describe ZombieKiller do
  context "one argument is a variable set to a literal" do
    it "translates Ops.add(variable, literal)" do
      c1 = 'v = "Hello"; Ops.add(v, "World")'
      c2 = 'v = "Hello"; v + "World"'
      expect(ZombieKiller.new.kill(c1)).to eq c2
    end

    it "translates Ops.add(literal, variable)" do
      c1 = 'v = "World"; Ops.add("Hello", v)'
      c2 = 'v = "World"; "Hello" + v'
      expect(ZombieKiller.new.kill(c1)).to eq c2
    end
  end

  context "argument is variable set to a literal, passed via another var" do
    it "translates Ops.add(variable, literal)" do
      c1 = 'v = "Hello"; v2 = v; Ops.add(v2, "World")'
      c2 = 'v = "Hello"; v2 = v; v2 + "World"'
      expect(ZombieKiller.new.kill(c1)).to eq c2
    end
  end

  context "one argument is a variable set to a literal but mutated" do
    it "does not translate Ops.add(variable, literal)" do
      c = 'v = "Hello"; v = f(v); Ops.add(v, "World")'
      expect(ZombieKiller.new.kill(c)).to eq c
    end
  end
end
