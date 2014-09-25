require "redcarpet"

class RSpecRenderer < Redcarpet::Render::Base
  INDENT_STEP = 2

  def initialize
    super

    @level = 0
    @separate = false
    @next_block_type = :unknown
  end

  def header(text, header_level)
    return nil if header_level == 1

    level = header_level - 1
    raise "Missing higher level header: #{text}" if level > @level + 1

    lines = []

    lines << pop_describe while @level >= level
    lines << "" if @separate
    lines << push_describe(text.downcase)

    join(lines)
  end

  def paragraph(text)
    if text =~ /^\*\*(.*)\*\*$/
      @next_block_type = $1.downcase.to_sym
    else
      @description = text.split(/\.(\s+|$)/).first.sub(/^Zombie Killer /, "")
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
        raise "Invalid next code block type: #@next_block_type."
    end
    @next_block_type = :unknown

    if @original_code && @translated_code
      lines = []

      it = @description =~ /XFAIL/ ? "xit" : "it"
      lines << "" if @separate
      lines << "#{it} \"#{@description}\" do"
      lines << "  original_code = cleanup(<" + "<-EOT)"     # splitting un-confuses Emacs
      lines << indent(@original_code, 2)
      lines << "  EOT"
      lines << ""
      lines << "  translated_code = cleanup(<" + "<-EOT)"   # splitting un-confuses Emacs
      lines << indent(@translated_code, 2)
      lines << "  EOT"
      lines << ""
      lines << "  expect(ZombieKiller.new.kill(original_code)).to eq(translated_code)"
      lines << "end"

      @original_code   = nil
      @translated_code = nil
      @separate        = true

      auto_indent(join(lines))
    else
      nil
    end
  end

  def doc_header
    join([
      "# Generated from spec/zombie_killer_spec.md -- do not change!",
      "",
      "require \"spec_helper\"",
      "",
      "describe ZombieKiller do",
    ])
  end

  def doc_footer
    lines = []

    lines << pop_describe while @level > 0
    lines << "end"

    join(lines)
  end

  private

  def join(lines)
    lines.map { |l| "#{l}\n" }.join("")
  end

  def indent(s, n)
    s.gsub(/^(?=.)/, " " * (INDENT_STEP * n))
  end

  def auto_indent(s)
    indent(s, @level + 1)
  end

  def push_describe(text)
    result = auto_indent("describe \"#{text}\" do")

    @level += 1
    @separate = false

    result
  end

  def pop_describe
    @level -= 1
    @separate = true

    auto_indent("end")
  end
end
