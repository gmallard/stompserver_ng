# -*- ruby -*-

# To regenerate gemspec for github
# rake debug_gem > stompserver_ng.gemspec

require 'rubygems'
require 'hoe'
$LOAD_PATH << "./lib"
require 'stomp_server'

Hoe.spec('stompserver_ng') do
  developer("Patrick Hurley", "phurley-blocked@rubyforge.org")
  developer("Lionel Bouton", "lionel-dev@bouton.name")
  developer("snacktime", "snacktime@somewhere.com")
  developer("gyver", "gyver@somewhere.com")
  developer("Mike Mangino", "mmangino-blocked@rubyforge.org")
  developer("robl", "robl@monkeyhelper.com")
  developer("gmallard", "allard.guy.m@gmail.com")
  #
  rubyforge_name = 'stompserver_ng'
  summary = 'A very light messaging server, next generation'
  self.description = self.paragraphs_of('README.txt', 1..1).join("\n\n")
  self.url = 'http://github.com/gmallard/stompserver_ng'
  self.extra_deps = [
    ["daemons", ">= 1.0.10"],
    ["eventmachine", ">= 0.12.10"],
    ["hoe", ">= 2.3.2"],
    ["uuid", ">= 2.1.0"],
  ]

end

# vim: syntax=Ruby
