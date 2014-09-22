class CodeHistogram
  attr_reader :counts

  def initialize
    @counts = Hash.new do |hash, key|
      hash[key] = 0
    end
  end

  def increment(key, value = 1)
    @counts[key] += value
  end

  def print_by_frequency(io)
    count_to_method = @counts.invert
    count_to_method.keys.sort.each do |c|
      io.printf("%4d %s\n", c, count_to_method[c])
    end
  end
end
