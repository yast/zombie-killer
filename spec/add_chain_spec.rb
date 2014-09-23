require_relative "spec_helper"

describe ZombieKiller do
  subject { ZombieKiller.new }

  context "since we have implemented iterated translation" do
    it 'translates a chain of Ops.add of literals' do
      c1 = 'Ops.add(Ops.add("Hello", " "), "World")'
      c2 = '("Hello" + " ") + "World"'
      expect(subject.kill(c1)).to eq c2
    end

    it "translates a right-assoc chain of Ops.add of literals" do
      c1 = 'Ops.add("Hello", Ops.add(" ", "World"))'
      c2 = '"Hello" + (" " + "World")'
      expect(subject.kill(c1)).to eq c2
    end
  end

  context "in case arguments are translated already" do
    it "translates Ops.add of plus and literal" do
      c1 = 'Ops.add("Hello" + " ", "World")'
      c2 = '("Hello" + " ") + "World"'
      expect(subject.kill(c1)).to eq c2
    end

    it "translates Ops.add of parenthesized plus and literal" do
      c1 = 'Ops.add(("Hello" + " "), "World")'
      c2 = '("Hello" + " ") + "World"'
      expect(subject.kill(c1)).to eq c2
    end

    it "translates Ops.add of literal and plus" do
      c1 = 'Ops.add("Hello", " " + "World")'
      c2 = '"Hello" + (" " + "World")'
      expect(subject.kill(c1)).to eq c2
    end
  end
end
