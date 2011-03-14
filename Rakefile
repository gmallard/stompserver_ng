# -*- ruby -*-
#
require 'rubygems'
$LOAD_PATH << "./lib"
require 'stomp_server_ng'
#
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "stompserver_ng"
    gem.version = StompServer::VERSION
    gem.summary = 'A very light messaging server, next generation'
    gem.description = 'STOMP Next Generation Ruby server.'
    gem.homepage = 'http://github.com/gmallard/stompserver_ng'
    gem.authors = ["Patrick Hurley",
      "Lionel Bouton",
      "snacktime",
      "gyver",
      "Mike Mangino",
      "robl",
      "gmallard" ]
    gem.email = ["phurley-blocked@rubyforge.org",
      "lionel-dev@bouton.name",
      "snacktime@somewhere.com",
      "gyver@somewhere.com",
      "mmangino-blocked@rubyforge.org",
      "robl@monkeyhelper.com",
      "allard.guy.m@gmail.com" ]
    #
    gem.add_dependency "daemons", ">= 1.0.10"
    gem.add_dependency "eventmachine", ">= 0.12.10"
    gem.add_dependency "uuid", ">= 2.1.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

