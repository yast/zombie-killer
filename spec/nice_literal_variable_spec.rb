require_relative "spec_helper"

describe ZombieKiller do
  it "translates Ops.add(variable set to literal, string literal)" do
    c1 = 'v = "Hello"; Ops.add(v, "World")'
    c2 = 'v = "Hello"; v + "World"'
    expect(ZombieKiller.new.kill(c1)).to eq c2
  end

  it "translates Ops.add(string literal, variable set to literal)" do
    c1 = 'v = "World"; Ops.add("Hello", v)'
    c2 = 'v = "World"; "Hello" + v'
    expect(ZombieKiller.new.kill(c1)).to eq c2
  end
end
