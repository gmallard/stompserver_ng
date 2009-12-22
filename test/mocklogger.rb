#
require 'logger'
#
module StompServer
  class LogHelper
    # Mock LogHelper Imlementation -> previous tests
    def self.get_loglevel
      Logger::DEBUG
    end # of self.get_loglevel
  end # of class LogHelper
end # of module

