#
require 'logger'
#
module StompServer
  class LogLevelHandler
    # Mock LogLevelHandler Imlementation -> previous tests
    def self.get_loglevel
      Logger::DEBUG
    end # of self.get_loglevel
  end # of class LogLevelHandler
end # of module

