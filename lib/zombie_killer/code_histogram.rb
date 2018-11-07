# frozen_string_literal: true

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
    count_to_methods = invert_hash_preserving_duplicates(@counts)

    count_to_methods.keys.sort.each do |c|
      count_to_methods[c].sort.each do |method|
        io.printf("%4d %s\n", c, method)
      end
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
    counts.merge!(other.counts) do |_key, count, other_count|
      count + other_count
    end
  end

  private

  def invert_hash_preserving_duplicates(h)
    ih = {}
    h.each do |k, v|
      ih[v] = [] unless ih.key?(v)
      ih[v] << k
    end
    ih
  end
end
