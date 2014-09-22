require_relative "spec_helper"

describe ZombieKiller do
  it "translates Ops.add of two string literals" do
    c1 = 'Ops.add("Hello", "World")'
    c2 = '"Hello" + "World"'
    expect(ZombieKiller.new.kill(c1)).to eq c2
  end

  it "does not translate Ops.add if any argument is ugly" do
    c1 = 'Ops.add("Hello", world)'
    expect(ZombieKiller.new.kill(c1)).to eq c1

    c2 = 'Ops.add(hello, "World")'
    expect(ZombieKiller.new.kill(c2)).to eq c2
  end
end
