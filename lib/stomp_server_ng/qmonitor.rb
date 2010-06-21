#
#
#
module StompServer
#
# = Queue Monitor
#
class QueueMonitor
  #
  # Initialize the queue monitor.
  #
  def initialize(qstore,queues)
    @qstore = qstore
    @queues = queues
    @stompid = StompServer::StompId.new
    #
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
    @@log.debug("QueueMonitor initialize comletes")
    #
  end
  #
  # Start monitor timer.
  #
  def start
    count =0
    EventMachine::add_periodic_timer 5, proc {count+=1; monitor(count) }
  end
  #
  # Respond to calls from the timer.  Do nothing if no clients are connected
  # to the '/queue/monitor' destination.
  #
  def monitor(count)
    return unless (@qstore.methods.include?(:monitor) | @qstore.methods.include?('monitor'))
    users = @queues['/queue/monitor']
    return if users.size == 0
    stats = @qstore.monitor
    return if stats.size == 0
    body = ''
    #
    stats.each do |queue,qstats|
      body << "Queue: #{queue}\n"
      qstats.each {|stat,value| body << "#{stat}: #{value}\n"}
      body << "\n"
    end
    #
    headers = {
      'message-id' => @stompid[count],
      'destination' => '/queue/monitor',
      'content-length' => body.size.to_s
    }
    #
    frame = StompServer::StompFrame.new('MESSAGE', headers, body)
    users.each {|user| user.connection.stomp_send_data(frame)}
  end
end # of class QueueMonitor
end # of module StompServer

