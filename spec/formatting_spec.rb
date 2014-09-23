require_relative "spec_helper"

describe ZombieKiller do
  subject { ZombieKiller.new }

  it "does not translate Ops.add if any argument has a comment" do
    c1 = <<EOS
Ops.add(
  "Hello",
  # foo
  "World"
)
EOS
    expect(subject.kill(c1)).to eq c1
  end
end
