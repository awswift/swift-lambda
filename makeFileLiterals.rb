#!/usr/bin/env ruby

out_path = File.expand_path '../Sources/FileLiterals.swift', __FILE__
out = File.open(out_path, 'w')

out.puts 'struct FileLiterals {'

dir = File.expand_path '../FileLiterals', __FILE__
Dir["#{dir}/*"].each do |path|
  name = File.basename path, File.extname(path)
  out.puts "    static let #{name} = ["
  File.readlines(path).each do |line|
    without_nl = line[0..-2]
    escaped = without_nl.gsub('"', '\"').gsub('\\', '\\\\')
    out.puts "        \"#{escaped}\","
  end
  out.puts '    ].joined(separator: "\n")'
  out.write "\n"
end

out.puts "}"
out.close
