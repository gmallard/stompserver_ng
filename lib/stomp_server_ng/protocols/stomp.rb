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
  :send,          # Explicit method supplied
  :subscribe,     # Explicit method supplied
  :unsubscribe    # Explicit method supplied
]
#
# = Stomp Protocol Handler.
#
class Stomp < EventMachine::Connection

  attr_reader :session_id, :conn_options

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
      lt = Time.now
      @session_id = "ssng_#{lt.to_f}"
    else
      @session_id = StompServer::SessionIDManager.get_cache_id(@@options[:session_cache])
    end
    @@log.debug("#{@session_id}  Session ID assigned")
    #
    @conn_options = { :protocol => StompServer::SPL_10, # Assume 1.0 at start
        :hbh => nil,   # No heartbeat handler for now
      }
    #
    @@log.warn("#{@session_id}  Protocol initialization complete")
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
    @sfr = StompServer::StompFrameRecognizer.new(@session_id)
    @transactions = {}
    @connected = false
    @@log.debug("#{@session_id} protocol post_init complete")
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
    @@log.warn "#{@session_id} Unbind called"
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
    raise "#{@session_id} Missing transaction" unless trans
    raise "#{@session_id} transaction does not exist: #{trans}" unless @transactions.has_key?(trans)
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
    raise "#{@session_id} Missing transaction" unless trans
    raise "#{@session_id} transaction exists" if @transactions.has_key?(trans)
    @transactions[trans] = []
  end
  #
  # Stomp Protocol - COMMIT
  #
  def commit(frame, trans=nil)
    raise "#{@session_id} Missing transaction" unless trans
    raise "#{@session_id} transaction does not exist" unless @transactions.has_key?(trans)
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
        raise "#{@session_id} {self} Invalid Login"
      end
    end
    @@log.warn "#{@session_id} attempting connect"
    response = _init_connection(frame)
    #
    stomp_send_data(response)
    if response.command == "CONNECTED"
      @connected = true
    else
      close_connection_after_writing
    end
  end
  #
  # Stomp Protocol - DISCONNECT
  #
  def disconnect(frame)
    @@log.warn "#{@session_id} Polite disconnect"
    close_connection_after_writing
  end
  #
  # Stomp Protocol - SEND
  #
  # The stomp SEND verb is by routing through:
  #
  # * receive_data(data)
  # * stomp_receive_data
  # * process_frames
  # * process_frame
  # * use Object#__send__ to call this method
  #
  def send(frame)
    # set message id
    if frame.dest.match(%r|^/queue|)
      @@queue_manager.sendmsg(frame)
    else
      frame.headers['message-id'] = "msg-#stompcma-#{@@topic_manager.next_index}"
      @@topic_manager.sendmsg(frame)
    end
  end
  #
  #
  # Stomp Protocol - SUBSCRIBE
  #
  # Delegated to the queue or topic manager.
  #
  def subscribe(frame)
    use_ack = false
    use_ack = true  if frame.headers['ack'] == 'client'
    #
    if frame.headers['id']
      subid = frame.headers['id']
    elsif frame.headers[:id]
      subid = frame.headers[:id]
    else
      subid = nil
    end
    #
    if frame.dest =~ %r|^/queue|
      @@queue_manager.subscribe(frame.dest, self, use_ack, subid)
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
  # stomp_receive_data
  #
  # Called from <tt>EM::Connection.receive_data(data)</tt>.  This is where
  # we begin processing a set of data fresh off the wire.
  # 
  def stomp_receive_data(data)
    begin
      # Limit log message length.
      logdata = data
      logdata = data[0..256] + "...truncated..." if data.length > 256
      @@log.debug "#{@session_id} stomp_receive_data: #{logdata.inspect}"
      # Append all data to the recognizer buffer.
      @sfr << data
      # Process any stomp frames in this set of data.
      process_frames
    rescue Exception => e
      @@log.error "#{@session_id} err: #{e} #{e.backtrace.join("\n")}"
      send_error(e.to_s)
      close_connection_after_writing
    end
  end 
  #
  # process_frames
  #
  # Handle all stomp frames currently in the recognizer's accumulated
  # array of frames.
  #
  def process_frames
    frame = nil
    @@log.debug "#{@session_id} Frames Array Size: #{@sfr.frames.size}"
#    process_frame(frame) while frame = @sfr.frames.shift
    while frame = @sfr.frames.shift
	    @@log.debug "#{@session_id} Next Frame: #{frame.inspect}"
			process_frame(frame)
		end
  end
  #
  # process_frame
  #
  # Process and individual stomp frame.
  #
  def process_frame(frame)
    cmd = frame.command.downcase.to_sym
    raise "#{@session_id}  Unhandled frame: #{cmd}" unless VALID_COMMANDS.include?(cmd)
    raise "#{@session_id}  Not connected" if !@connected && cmd != :connect
    @@log.debug("#{@session_id} process_frame: #{frame.command}")
    # Add session ID to the frame headers
    frame.headers['session'] = @session_id
    # Send receipt first if required
    send_receipt(frame.headers['receipt']) if frame.headers['receipt']
    #
    if trans = frame.headers['transaction']
      # Handle transactional frame if required.
      handle_transaction(frame, trans, cmd)
    else
      # Otherwise, just route the non-transactional frame.
      __send__(cmd, frame) # Object#send alias call
    end
  end
  #
  # handle_transaction  
  #
  def handle_transaction(frame, trans, cmd)
    if [:begin, :commit, :abort].include?(cmd)
      __send__(cmd, frame, trans) # Object#send alias call
    else
      raise "#{@session_id} transaction does not exist" unless @transactions.has_key?(trans)
      @transactions[trans] << frame
    end    
  end
  #
  # send_error
  #
  # Send a single error frame.
  #
  def send_error(msg, headers = {'message' => 'See below'})
    send_frame("ERROR", headers, msg)
  end
  #
  # send_frame
  #
  # Send an individual stomp frame.
  #
  def send_frame(command, headers={}, body='')
    headers['content-length'] = body.size.to_s
    response = StompServer::StompFrame.new(command, headers, body)
    stomp_send_data(response)
  end
  #
  # send_receipt
  #
  # Send a single receipt frame.
  # 
  def send_receipt(id)
    send_frame("RECEIPT", { 'receipt-id' => id})
  end
  #
  # stomp_send_data
  #
  def stomp_send_data(frame)
    @@log.debug "#{@session_id} Sending frame #{frame.to_s}"
    send_data(frame.to_s)
  end

  #
  private

  def _init_connection(frame)
    response = StompServer::StompFrame.new("CONNECTED", {'session' => @session_id})
    er = StompServer::StompFrame.new("ERROR", {})
    return response if frame.headers["accept-version"].nil? && frame.headers["host"].nil?
    # Required headers checks
    if frame.headers["accept-version"].nil?
      er.headers["no-protocol"] = "missing"
      er.body = "The 'accept-version' header is required."
      return er
    end
    #
    if frame.headers["host"].nil?
      er.headers["no-host"] = "missing"
      er.body = "The 'host' header is required."
      return er
    end
    # Protocol match determination
    cp = frame.headers["accept-version"].split(",")
    use_proto = nil
    (StompServer::SUPPORTED.size-1).downto(0) do |i|
      use_proto = cp.include?(StompServer::SUPPORTED[i]) ? StompServer::SUPPORTED[i] : nil
      break if use_proto
    end
    unless use_proto
      er.headers["no-protocol"] = "not-supported"
      er.body = "Supported protocol levels are: " + StompServer::SUPPORTED.join(",")
      return er
    end
    response.headers["version"] = use_proto
    @conn_options[:protocol] = use_proto
    # Server Identity
    response.headers["server"] = StompServer::VHOST + "/" + StompServer::VERSION
    # Heart beat checks: TODO
    if @conn_options[:protocol] >= StompServer::SPL_11 # 1.1 connections might use heartbeats
      response.headers["heart-beat"] = @@options[:heart_beat] # Server default is: 0,0
      if frame.headers["heart-beat"] && frame.headers["heart-beat"] != "0,0" && @@options[:heart_beat] != "0,0"
        # set up heartbeats here
        raise "TODO: Add hearbeat support"
      end
    else # 1.0 connections do not use heartbeats
      response.headers["heart-beat"] = "0,0"
    end
    #
    response
  end

end # class Stomp < EventMachine::Connection
#
end # module StompServer::Protocols
end # module StompServer

