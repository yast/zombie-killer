require_relative "spec_helper"

describe ZombieKiller do
  it "translates Ops.add of two string literals" do
    c1 = "Ops.add('Hello', 'World')"
    c2 = "'Hello' + 'World'"
    expect(ZombieKiller.new.kill(c1)).to eq c2
  end
end
