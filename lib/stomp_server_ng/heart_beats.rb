#
# 1.1+ Heartbeat support
#
module StompServer
  #
  # Implement heartbeating if required
  #
  class HeartBeats
    def initialize()
      #
      @@log = Logger.new(STDOUT)
      @@log.level = StompServer::LogHelper.get_loglevel()
    end
   
  end
end

