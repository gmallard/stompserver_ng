#
module StompServer
module StompServer::Protocols
#
VALID_COMMANDS = [
  :abort,         # Explicit method supplied
  :ack,           # Explicit method supplied
  :begin,         # Explicit method supplied
  :commit,        # Explicit method supplied
  :connect,       # Explicit method supplied
  :disconnect,    # Explicit method supplied
  :send,          # No method supplied.  The <tt>EM::Connection.receive_data</tt>
                  # method delegates the SEND verb to the 
                  # <tt>stomp_receive_data</tt> helper method.
  :subscribe,     # Explicit method supplied
  :unsubscribe    # Explicit method supplied
]
#
# = Stomp Protocol Handler.
#
class Stomp < EventMachine::Connection

  # Protocol handler initialization
  def initialize(*args)
    super(*args)
    #
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
    #
    @@options = (Hash === args.last) ? args.pop : {}
    # Arguments are passed from EventMachine::start_server
    @@auth_required = args[0]
    @@queue_manager = args[1]
    @@topic_manager = args[2]
    @@stompauth =     args[3]
    #
    # N.B.: The session ID is an instance variable!
    #
    if @@options[:session_cache] == 0
      @session_id = "wow"
    else
      @session_id = StompServer::SessionIDManager.get_cache_id(@@options[:session_cache])
    end
    @@log.debug("#{self} Session ID assigned: #{@session_id}")
    #
    @@log.warn("#{self} Protocol initialization complete, session=#{@session_id}")
  end

# :stopdoc:
#
# <tt>EM::Connection.close_connection()</tt>
#
# <tt>EM::Connection.close_connection_after_writing()</tt>
#
# <tt>EM::Connection.comm_inactivity_timeout()</tt>
#
# <tt>EM::Connection.comm_inactivity_timeout=(value)</tt>
#
# <tt>EM::Connection.connection_completed()</tt>
#
# <tt>EM::Connection.detach()</tt>
#
# <tt>EM::Connection.error?()</tt>
#
# <tt>EM::Connection.get_peer_cert()</tt>
#
# <tt>EM::Connection.get_peername()</tt>
#
# <tt>EM::Connection.get_pid()</tt>
#
# <tt>EM::Connection.get_sock_opt(level,option)</tt>
#
# <tt>EM::Connection.get_sockname()</tt>
#
# <tt>EM::Connection.get_status()</tt>
#
# <tt>EM::Connection.notify_readable=(mode)</tt>
#
# <tt>EM::Connection.notify_readable?()</tt>
#
# <tt>EM::Connection.notify_writable=(mode)</tt>
#
# <tt>EM::Connection.notify_writable?()</tt>
#
# <tt>EM::Connection.pause()</tt>
#
# <tt>EM::Connection.paused?()</tt>
#
# <tt>EM::Connection.pending_connect_timeout()</tt>
#
# <tt>EM::Connection.pending_connect_timeout=(value)</tt>
#

# :startdoc:

  # <tt>EM::Connection.post_init()</tt>
  #
  # Protocol handler post initialization.
  def post_init
    @sfr = StompServer::StompFrameRecognizer.new
    @transactions = {}
    @connected = false
    @@log.debug("#{self} protocol post_init complete")
  end

# :stopdoc:

#
# <tt>EM::Connection.proxy_incoming_to(conn,bufsize=0)</tt>
#
# <tt>EM::Connection.proxy_target_unbound()</tt>
#

# :startdoc:

  # <tt>EM::Connection.receive_data(data)</tt>
  #
  # Delegate to stomp_receive_data helper.
  #
  def receive_data(data)
    stomp_receive_data(data)
  end

# :stopdoc:

# <tt>EM::Connection.reconnect(server,port)</tt>
#
# <tt>EM::Connection.resume()</tt>
#

# :startdoc:

  # <tt>EM::Connection.send_data(data)</tt>
  #
  # Just calls super.
  #
  def send_data(data)
    super(data)
  end  

# :stopdoc:

# <tt>EM::Connection.send_datagram(data,recipient_address,recipient_port)</tt>
#
# <tt>EM::Connection.send_file_data(filename)</tt>
#
# <tt>EM::Connection.set_comm_inactivity_timeout(value)</tt>
#
# <tt>EM::Connection.set_pending_connect_timeout(value)</tt>
#
# <tt>EM::Connection.ssl_handshake_completed()</tt>
#
# <tt>EM::Connection.ssl_verify_peer(cert)</tt>
#
# <tt>EM::Connection.start_tls(args={})</tt>
#
# <tt>EM::Connection.stop_proxying()</tt>
#
# <tt>EM::Connection.stream_file_data(filename, args={})</tt>
#

# :startdoc:

  # <tt>EM::Connection.unbind()</tt>
  #
  # Unbind the connection.
  #
  def unbind()
    @@log.warn "#{self} Unbind called, session=#{@session_id}"
    @connected = false
    @@queue_manager.disconnect(self)
    @@topic_manager.disconnect(self)
  end

# :stopdoc:

# Stomp Protocol Verbs

# :startdoc:
  #
  # Stomp Protocol - ABORT
  #
  def abort(frame, trans=nil)
    raise "#{self} Missing transaction" unless trans
    raise "#{self} transaction does not exist" unless @transactions.has_key?(trans)
    @transactions.delete(trans)
  end
  #
  # Stomp Protocol - ACK
  #
  # Delegated to the queue manager.
  #
  def ack(frame)
    @@queue_manager.ack(self, frame)
  end
  #
  # Stomp Protocol - BEGIN
  #
  def begin(frame, trans=nil)
    raise "#{self} Missing transaction" unless trans
    raise "#{self} transaction exists" if @transactions.has_key?(trans)
    @transactions[trans] = []
  end
  #
  # Stomp Protocol - COMMIT
  #
  def commit(frame, trans=nil)
    raise "#{self} Missing transaction" unless trans
    raise "#{self} transaction does not exist" unless @transactions.has_key?(trans)
    #    
    (@transactions[trans]).each do |frame|
      frame.headers.delete('transaction')
      process_frame(frame)
    end
    @transactions.delete(trans)
  end
  #
  # Stomp Protocol - CONNECT
  #
  def connect(frame)
    if @@auth_required
      unless frame.headers['login'] and frame.headers['passcode'] and  @@stompauth.authorized[frame.headers['login']] == frame.headers['passcode']
        raise "#{self} Invalid Login"
      end
    end
    @@log.warn "#{self} Connecting, session=#{@session_id}"
    response = StompServer::StompFrame.new("CONNECTED", {'session' => @session_id})
    #
    stomp_send_data(response)
    @connected = true
  end
  #
  # Stomp Protocol - DISCONNECT
  #
  def disconnect(frame)
    @@log.warn "#{self} Polite disconnect, session=#{@session_id}"
    close_connection_after_writing
  end

  # :stopdoc:

  #
  # Stomp Protocol - SEND
  #
  # No method supplied. The stomp SEND verb is handled from the 
  # receive_data(data) method which delegates to
  # the <tt>stomp_receive_data</tt> method.
  #

  # :startdoc:

  #
  #
  # Stomp Protocol - SUBSCRIBE
  #
  # Delegated to the queue or topic manager.
  #
  def subscribe(frame)
    use_ack = false
    use_ack = true  if frame.headers['ack'] == 'client'
    if frame.dest =~ %r|^/queue|
      @@queue_manager.subscribe(frame.dest, self,use_ack)
    else
      @@topic_manager.subscribe(frame.dest, self)
    end
  end
  #
  # Stomp Protocol - UNSUBSCRIBE
  #
  # Delegated to the queue or topic manager.
  #
  def unsubscribe(frame)
    if frame.dest =~ %r|^/queue|
      @@queue_manager.unsubscribe(frame.dest,self)
    else
      @@topic_manager.unsubscribe(frame.dest,self)
    end
  end

  # :stopdoc:

  # Helper methods

  # :startdoc:

  #
  # connected?
  #
  def connected?
    @connected
  end
  #
  # handle_transaction  
  #
  def handle_transaction(frame, trans, cmd)
    if [:begin, :commit, :abort].include?(cmd)
      send(cmd, frame, trans) # WARNING: call Object#send !!!
    else
      raise "#{self} transaction does not exist" unless @transactions.has_key?(trans)
      @transactions[trans] << frame
    end    
  end
  #
  # process_frame
  #
  def process_frame(frame)
    cmd = frame.command.downcase.to_sym
    raise "#{self} Unhandled frame: #{cmd}" unless VALID_COMMANDS.include?(cmd)
    raise "#{self} Not connected" if !@connected && cmd != :connect
    @@log.debug("process_frame: cmd: #{cmd}")
    # Send receipt first if required
    send_receipt(frame.headers['receipt']) if frame.headers['receipt']
    #
    # I really like this code, but my needs are a little trickier
    # 
    if trans = frame.headers['transaction']
      handle_transaction(frame, trans, cmd)
    else
      cmd = :sendmsg if cmd == :send
      send(cmd, frame) # WARNING: call Object#send !!!
    end
  end
  #
  # process_frames
  #
  def process_frames
    frame = nil
    process_frame(frame) while frame = @sfr.frames.shift
  end
  #
  # send_error
  #
  def send_error(msg)
    send_frame("ERROR",{'message' => 'See below'},msg)
  end
  #
  # send_frame
  #
  def send_frame(command, headers={}, body='')
    headers['content-length'] = body.size.to_s
    response = StompServer::StompFrame.new(command, headers, body)
    stomp_send_data(response)
  end
  #
  # send_message
  #
  def send_message(msg)
    msg.command = "MESSAGE"
    stomp_send_data(msg)
  end
  #
  # send_receipt
  # 
  def send_receipt(id)
    send_frame("RECEIPT", { 'receipt-id' => id})
  end
  #
  # sendmsg
  #
  def sendmsg(frame)
    # set message id
    if frame.dest.match(%r|^/queue|)
      @@queue_manager.sendmsg(frame)
    else
      frame.headers['message-id'] = "msg-#stompcma-#{@@topic_manager.next_index}"
      @@topic_manager.sendmsg(frame)
    end
  end
  #
  # stomp_receive_data
  # 
  def stomp_receive_data(data)
    begin
      @@log.debug "#{self} receive_data: #{data.inspect}"
      @sfr << data
      process_frames
    rescue Exception => e
      @@log.error "#{self} err: #{e} #{e.backtrace.join("\n")}"
      send_error(e.to_s)
      close_connection_after_writing
    end
  end 
  #
  # stomp_receive_frame
  #
  def stomp_receive_frame(frame)
    begin
      @@log.debug "#{self} receive_frame: #{frame.inspect}"
      process_frame(frame)
    rescue Exception => e
      @@log.error "#{self} err: #{e} #{e.backtrace.join("\n")}"
      send_error(e.to_s)
      close_connection_after_writing
    end
  end
  #
  # stomp_send_data
  #
  def stomp_send_data(frame)
    send_data(frame.to_s)
    @@log.debug "#{self} Sending frame #{frame.to_s}"
  end

  #
end # class Stomp < EventMachine::Connection
#
end # module StompServer::Protocols
end # module StompServer

