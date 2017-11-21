require 'seeing_is_believing'

EXCLUDE_PATTERNS = [/\$:.unshift/, /^require/, /^\#/]

def see_here(file, line)
  lines = File.read(file).split("\n")[(line+1)..-1]
  handler = SeeingIsBelieving.call(lines.join("\n"))
  max_length = lines
    .reject { |ln| EXCLUDE_PATTERNS.any? { |p| ln.match(p) } }
    .map(&:length).max + 1
  lines.each_with_index { |ln, i|
    print ln.ljust(max_length)
    if EXCLUDE_PATTERNS.any? { |p| ln.match(p) }
      puts
      next
    end

    res = handler.result[i + 1].first

    case res
    when nil
      puts
    when /\n/
      resl = res.split("\n")
      puts "\n# => #{resl.first}\n# " + resl[1..-1].join("\n# ")
    else
      puts "# => #{res}"
    end
  }
  exit
end
