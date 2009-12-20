# -*- ruby -*-

# To regenerate gemspec for github
# rake debug_gem > stompserver.gemspec

require 'rubygems'
require 'hoe'
$LOAD_PATH << "./lib"
require 'stomp_server'

Hoe.spec('stompserver') do
  developer("Patrick Hurley", "phurley-blocked@rubyforge.org")
  developer("Lionel Bouton", "lionel-dev@bouton.name")
  developer("snacktime", "snacktime@somewhere.com")
  developer("gyver", "gyver@somewhere.com")
  developer("Mike Mangino", "mmangino-blocked@rubyforge.org")
  developer("robl", "robl@monkeyhelper.com")
  developer("Guy Allard", "allard.guy.m@gmail.com")
  #
  rubyforge_name = 'stompserver'
  summary = 'A very light messaging server'
  self.description = self.paragraphs_of('README.txt', 1..1).join("\n\n")
  self.url = 'http://rubyforge.org/projects/stompserver'
  self.extra_deps = [
    ["daemons", ">= 1.0.10"],
    ["eventmachine", ">= 0.12.8"],
    ["hoe", ">= 2.3.2"],
  ]

end

# vim: syntax=Ruby
