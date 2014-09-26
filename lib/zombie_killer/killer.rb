require "parser"
require "parser/current"

require_relative "rewriter"

class ZombieKiller
  # @returns new string
  def kill_string(code, filename = "(inline code)", unsafe: false)
    fixed_point(code) do |c|
      parser   = Parser::CurrentRuby.new
      rewriter = ZombieKillerRewriter.new(unsafe: unsafe)
      buffer   = Parser::Source::Buffer.new(filename)
      buffer.source = c
      rewriter.rewrite(buffer, parser.parse(buffer))
    end
  end
  alias_method :kill, :kill_string

  # @param new_filename may be the same as *filename*
  def kill_file(filename, new_filename, unsafe: false)
    new_string = kill_string(File.read(filename), filename, unsafe: unsafe)

    File.write(new_filename, new_string)
  end

  private

  def fixed_point(x, &lambda_x)
    while true
      y = lambda_x.call(x)
      return y if y == x
      x = y
    end
  end
end
