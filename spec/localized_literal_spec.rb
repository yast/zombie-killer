require_relative "spec_helper"

describe ZombieKiller do
  context "argument is a variable set to a localized literal" do
    it "translates Ops.add(variable, literal)" do
      c1 = 'v = _("Hello"); Ops.add(v, "World")'
      c2 = 'v = _("Hello"); v + "World"'
      expect(ZombieKiller.new.kill(c1)).to eq c2
    end

    it "translates Ops.add(variable, localized literal)" do
      c1 = 'v = _("Hello"); Ops.add(v, _("World"))'
      c2 = 'v = _("Hello"); v + _("World")'
      expect(ZombieKiller.new.kill(c1)).to eq c2
    end
  end
end
