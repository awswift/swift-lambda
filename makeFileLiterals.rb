#!/usr/bin/env ruby

def literal_definition(path)
  str = StringIO.new
  name = path.gsub('/', '_').chomp File.extname(path)
  # name = File.basename path, File.extname(path)

  str.puts "    static let #{name} = ["
  File.readlines("FileLiterals/#{path}").each do |line|
    without_nl = line[0..-2]
    escaped = without_nl.gsub('"', '\"').gsub('\\', '\\\\')
    str.puts "        \"#{escaped}\","
  end
  str.puts '    ].joined(separator: "\n")'

  str.rewind
  str.read
end

out_path = File.expand_path '../Sources/SwiftdaKit/FileLiterals.swift', __FILE__
out = File.open(out_path, 'w')

out.puts 'struct FileLiterals {'

dir = File.expand_path '../FileLiterals', __FILE__

Dir["#{dir}/**/*"].each do |path|
  next if File.directory? path
  relative_path = path[dir.length+1..-1]
  defn = literal_definition relative_path
  out.puts defn
  out.write "\n"
end

out.puts "}"
out.close
