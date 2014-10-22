require "redcarpet"

require_relative "../lib/zombie_killer"

# Utility functions for manipulating code.
module Code
  INDENT_STEP = 2

  class << self
    def join(lines)
      lines.map { |l| "#{l}\n" }.join("")
    end

    def indent(s)
      s.gsub(/^(?=.)/, " " * INDENT_STEP)
    end
  end
end

# Represents RSpec's "it" block.
class It
  def initialize(attrs)
    @description = attrs[:description]
    @code        = attrs[:code]
    @skip        = attrs[:skip]
  end

  def render
    [
      "#{@skip ? "xit" : "it"} #{@description.inspect} do",
      Code.indent(@code),
      "end"
    ].join("\n")
  end
end

# Represents RSpec's "describe" block.
class Describe
  attr_reader :blocks

  def initialize(attrs)
    @description = attrs[:description]
    @blocks      = attrs[:blocks]
  end

  def render
    parts = []
    parts << "describe #{@description.inspect} do"
    if !blocks.empty?
      parts << Code.indent(@blocks.map(&:render).join("\n\n"))
    end
    parts << "end"
    parts.join("\n")
  end
end

class RSpecRenderer < Redcarpet::Render::Base
  def initialize
    super

    @next_block_type = :unknown
    @describe = Describe.new(description: "ZombieKiller:", blocks: [])
  end

  def header(text, header_level)
    return nil if header_level == 1

    if header_level > describes_depth + 1
      raise "Missing higher level header: #{text}"
    end

    describe_at_level(header_level - 1).blocks << Describe.new(
      description: text.downcase + ":",
      blocks:      []
    )

    nil
  end

  def paragraph(text)
    if text =~ /^\*\*(.*)\*\*$/
      @next_block_type = $1.downcase.to_sym
    else
      first_sentence = text.split(/\.(\s+|$)/).first
      @description = first_sentence.sub(/^Zombie Killer /, "").sub(/\n/, " ")
    end

    nil
  end

  def block_code(code, language)
    case @next_block_type
      when :original
        @original_code = code[0..-2]
      when :translated
        @translated_code = code[0..-2]
      when :unchanged
        @original_code = @translated_code = code[0..-2]
      else
        raise "Invalid next code block type: #@next_block_type.\n#{code}"
    end
    @next_block_type = :unknown

    if @original_code && @translated_code
      current_describe.blocks << It.new(
        description: @description,
        code:        generate_test_code,
        skip:        @description =~ /XFAIL/
      )

      @original_code   = nil
      @translated_code = nil
    end

    nil
  end

  def doc_header
    Code.join([
      "# Generated from spec/zombie_killer_spec.md -- do not change!",
      "",
      "require \"spec_helper\"",
      "",
    ])
  end

  def doc_footer
    "#{@describe.render}\n"
  end

  private

  def describes_depth
    describe = @describe
    depth = 1
    while describe.blocks.last.is_a?(Describe)
      describe = describe.blocks.last
      depth += 1
    end
    depth
  end

  def current_describe
    describe = @describe
    while describe.blocks.last.is_a?(Describe)
      describe = describe.blocks.last
    end
    describe
  end

  def describe_at_level(level)
    describe = @describe
    2.upto(level) do
      describe = describe.blocks.last
    end
    describe
  end

  def generate_test_code
    [
      "original_code = cleanup(<" + "<-EOT)",     # splitting un-confuses Emacs
      Code.indent(@original_code),
      "EOT",
      "",
      "translated_code = cleanup(<" + "<-EOT)",   # splitting un-confuses Emacs
      Code.indent(@translated_code),
      "EOT",
      "",
      "expect(ZombieKiller.new.kill(original_code)).to eq(translated_code)"
    ].join("\n")
  end
end
