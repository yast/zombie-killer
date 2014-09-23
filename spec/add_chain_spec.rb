require_relative "spec_helper"

describe ZombieKiller do
  subject { ZombieKiller.new }

  context "while we keep operating on the original AST, recursion won't work" do
    xit 'translates a chain of Ops.add of literals' do
      c1 = 'Ops.add(Ops.add("Hello", " "), "World")'
      c2 = '("Hello" + " ") + "World"'
      expect(subject.kill(c1)).to eq c2
    end

    xit "translates a right-assoc chain of Ops.add of literals" do
      c1 = 'Ops.add("Hello", Ops.add(" ", "World"))'
      c2 = '"Hello" + (" " + "World")'
      expect(subject.kill(c1)).to eq c2
    end
  end
end
