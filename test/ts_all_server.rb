#
# Run all tests which require a server instance to be up.
#
here=File.dirname(__FILE__)
Dir.glob("#{here}/test_0*.rb").each do |file|
  next if file =~ /_0000_/
  puts "Will require unit test file: #{file}"
  require file
end

