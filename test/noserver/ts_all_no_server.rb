#
# Run all tests which do not require a server instance to be up.
#
here=File.dirname(__FILE__)
$:.unshift File.join(here,"..","..", "lib")
$:.unshift File.join(here)
Dir.glob("#{here}/test_*.rb").each do |file|
#  next if file =~ /test_0/
  puts "Will require unit test file: #{file}"
  require file
end

