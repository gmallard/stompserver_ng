# -*- ruby -*-

# To regenerate gemspec for github
# rake debug_gem > stompserver.gemspec

require 'rubygems'
require 'hoe'
$LOAD_PATH << "./lib"
require 'stomp_server'

Hoe.spec('stompserver') do
  developer("Lionel Bouton", "lionel-dev@bouton.name")
  rubyforge_name = 'stompserver'
  summary = 'A very light messaging server'
  self.description = self.paragraphs_of('README.txt', 2..4).join("\n\n")
  self.changes = self.paragraphs_of('History.txt', 0..1).join("\n\n")
  url = 'http://rubyforge.org/projects/stompserver'
  self.extra_deps = [
    ["daemons", ">= 1.0.10"],
    ["eventmachine", ">= 0.12.8"],
    ["hoe", ">= 2.3.2"],
  ]

end

# vim: syntax=Ruby
