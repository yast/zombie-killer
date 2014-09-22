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

  def self.parse_by_frequency(lines)
    histogram = CodeHistogram.new
    lines.each do |line|
      /^\s*(\d*)\s*(.*)/.match(line.chomp) do |m|
        histogram.increment(m[2], m[1].to_i)
      end
    end
    histogram
  end

  def merge!(other)
    counts.merge!(other.counts) do |key, count, other_count|
      count + other_count
    end
  end
end
