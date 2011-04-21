#
# = QueueManager 
#
# Used in conjunction with a storage class.  
#
# The storage class MUST implement the following methods:
#
# * enqueue(queue name, frame)
#
# enqueue pushes a frame to the top of the queue in FIFO order. It's return 
# value is ignored. enqueue must also set the message-id and add it to the 
# frame header before inserting the frame into the queue.
#
# * dequeue(queue name)
#
# removes a frame from the bottom of the queue and returns it.
#
# * requeue(queue name,frame)
#
# does the same as enqueue, except it pushes the given frame to the 
# bottom of the queue.
#
# The storage class MAY implement the following methods:
#
# * stop() method which should
#
# do any housekeeping that needs to be done before stompserver shuts down. 
# stop() will be called when stompserver is shut down.
#
# * monitor() method which should
#
# return a hash of hashes containing the queue statistics.
# See the file queue for an example. Statistics are available to clients 
# in /queue/monitor.
#
module StompServer
#
class QueueManager
  Struct::new('QueueUser', :connection, :ack, :subid)
  #
  # Queue manager initialization.
  #
  def initialize(qstore)
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
    @@log.debug("QM QueueManager initialize comletes")
    #
    @qstore = qstore
    @queues = Hash.new { Array.new }
    @pending = Hash.new
    if $STOMP_SERVER
      monitor = StompServer::QueueMonitor.new(@qstore,@queues)
      monitor.start
      @@log.debug "QM monitor started by QM initialization"
    end
  end
  #
  # Server stop / shutdown.
  #
  def stop(session_id)
    @qstore.stop(session_id) if (@qstore.methods.include?('stop') || @qstore.methods.include?(:stop))
  end
  #
  # Client subscribe for a destination.
  #
  # Called from the protocol handler (subscribe method).
  #
  def subscribe(dest, connection, use_ack=false, subid = nil)
    @@log.debug "#{connection.session_id} QM subscribe to #{dest}, ack => #{use_ack}, connection: #{connection}, subid: #{subid}"
    user = Struct::QueueUser.new(connection, use_ack, subid)
    @queues[dest] += [user]
    send_destination_backlog(dest,user) unless dest == '/queue/monitor'
  end
  #
  # send_a_backlog
  #
  # Send at most one frame to a connection.
  # Used when use_ack == true.
  # Called from the ack method.
  #
  def send_a_backlog(connection)
    @@log.debug "#{connection.session_id} QM send_a_backlog starts"
    #
    # lookup queues with data for this connection
    #

    # :stopdoc:

    # 1.9 compatability
    #
    # The Hash#select method returns:
    #
    # * An Array (of Arrays) in Ruby 1.8
    # * A Hash in Ruby 1.9
    #
    # Watch the code in this method.  It is a bit ugly because of that
    # difference.

    # :startdoc:

    possible_queues = @queues.select{ |destination, users|
      @qstore.message_for?(destination, connection.session_id) &&
        users.detect{|u| u.connection == connection}
    }
    if possible_queues.empty?
      @@log.debug "#{connection.session_id} QM  s_a_b nothing to send"
      return
    end
    #
    # Get a random one (avoid artificial priority between queues
    # without coding a whole scheduler, which might be desirable later)
    #
    # Select a random destination from those possible

    # :stopdoc:

    # Told ya' this would get ugly.  A quote from the Pickaxe.  I am:
    #
    # 'abandoning the benefits of polymorphism, and bringing the gods of refactoring down around my ears'
    #
    # :-)

    # :startdoc:

# The following log call results in an exception using 1.9.2p180.  I cannot
# recreate this using IRB.  It has something to do with 'Struct's I think.
#    @@log.debug("#{connection.session_id} possible_queues: #{possible_queues.inspect}")


    case possible_queues
      when Hash
        #  possible_queues _is_ a Hash
        dests_possible = possible_queues.keys     # Get keys of a Hash of destination / queues
        dest_index = rand(dests_possible.size)    # Random index
        dest = dests_possible[dest_index]         # Select a destination / queue
        # The selected destination has (possibly) multiple users.
        # Select a random user from those possible
        user_index = rand(possible_queues[dest].size) # Random index
        user = possible_queues[dest][user_index]  # Array entry from Hash table entry
        #
      when Array
        # possible_queues _is_ an Array
        dest_index = rand(possible_queues.size)    # Random index
        dest_data = possible_queues[dest_index]    # Select a destination + user array
        dest = dest_data[0]                        # Select a destination / queue
        # The selected destination has (possibly) multiple users.
        # Select a random user from those possible
        user_index = rand(dest_data[1].size)     # Random index
        user = dest_data[1][user_index]  # Array entry from Hash table entry
      else
        raise "#{connection.session_id} something is very not right : #{RUBY_VERSION}"
    end

    #
    @@log.debug "#{connection.session_id} QM s_a_b chosen -> dest: #{dest}"
# Ditto for this log statement using 1.9.2p180.
#    @@log.debug "#{connection.session_id} QM s_a_b chosen -> user: #{user}"
    #
    frame = @qstore.dequeue(dest, connection.session_id)
    send_to_user(frame, user)
  end
  #
  # send_destination_backlog
  #
  # Called from the subscribe method.
  #
  def send_destination_backlog(dest,user)
    @@log.debug "#{user.connection.session_id} QM send_destination_backlog for #{dest}"
    if user.ack
      # Only send one message, then wait for client ACK.
      frame = @qstore.dequeue(dest, user.connection.session_id)
      if frame
        send_to_user(frame, user)
        @@log.debug("#{user.connection.session_id} QM s_d_b single frame sent")
      end
    else
      # Send all available messages.
      while frame = @qstore.dequeue(dest, user.connection.session_id)
        send_to_user(frame, user)
      end
    end
  end
  #
  # Client unsubscribe.
  #
  # Called from the protocol handler (unsubscribe method).
  #
  def unsubscribe(dest, connection)
    @@log.debug "#{connection.session_id} QM unsubscribe from #{dest}, connection #{connection}"
    @queues.each do |d, queue|
      queue.delete_if { |qu| qu.connection == connection and d == dest}
    end
    @queues.delete(dest) if @queues[dest].empty?
  end
  #
  # Client ack.
  #
  # Called from the protocol handler (ack method).
  #
  def ack(connection, frame)
    @@log.debug "#{connection.session_id} QM ACK."
    @@log.debug "#{connection.session_id} QM ACK for frame: #{frame.inspect}"
    unless @pending[connection]
      @@log.debug "#{connection.session_id} QM No message pending for connection!"
      return
    end
    msgid = frame.headers['message-id']
    p_msgid = @pending[connection].headers['message-id']
    if p_msgid != msgid
      @@log.debug "#{connection.session_id} QM ACK Invalid message-id (received /#{msgid}/ != /#{p_msgid}/)"
      # We don't know what happened, we requeue
      # (probably a client connecting to a restarted server)
      frame = @pending[connection]
      @qstore.requeue(frame.headers['destination'],frame)
    end
    @pending.delete connection
    # We are free to work now, look if there's something for us
    send_a_backlog(connection)
  end
  #
  # Client disconnect.
  #
  # Called from the protocol handler (unbind method).
  #
  def disconnect(connection)
    @@log.debug("#{connection.session_id} QM DISCONNECT.")
    frame = @pending[connection]
    @@log.debug("#{connection.session_id} QM DISCONNECT pending frame: #{frame.inspect}")
    if frame
      @qstore.requeue(frame.headers['destination'],frame)
      @pending.delete connection
    end
    #
    @queues.each do |dest, queue|
      queue.delete_if { |qu| qu.connection == connection }
      @queues.delete(dest) if queue.empty?
    end
  end
  #
  # send_to_user
  #
  def send_to_user(frame, user)
    @@log.debug("#{user.connection.session_id} QM send_to_user")
    connection = user.connection
    frame.headers['subscription'] = user.subid if user.subid
    if user.ack
      # raise on internal logic error.
      raise "#{user.connection.session_id} other connection's end already busy" if @pending[connection]
      # A maximum of one frame can be pending ACK.
      @pending[connection] = frame
    end
    connection.stomp_send_data(frame)
  end
  #
  # sendmsg
  #
  # Called from the protocol handler (sendmsg method, process_frame method).
  #
  def sendmsg(frame)
    #
    @@log.debug("#{frame.headers['session']} QM client SEND Processing, #{frame}")
    frame.command = "MESSAGE"
    dest = frame.headers['destination']
    # Lookup a user willing to handle this destination
    available_users = @queues[dest].reject{|user| @pending[user.connection]}
    if available_users.empty?
      @qstore.enqueue(dest,frame)
      return
    end
    #
    # Look for a user with ack (we favor reliability)
    #
    reliable_user = available_users.find{|u| u.ack}
    #
    if reliable_user
      # give it a message-id
      @qstore.assign_id(frame, dest)
      send_to_user(frame, reliable_user)
    else
      random_user = available_users[rand(available_users.length)]
      # Note message-id header isn't set but we won't need it anyway
      # <TODO> could break some clients: fix this
      send_to_user(frame, random_user)
    end
  end
  #
  # dequeue: remove a message from a queue.
  #
  def dequeue(dest, session_id)
    @qstore.dequeue(dest, session_id)
  end
  #
  # enqueue: add a message to a queue.
  #
  def enqueue(frame)
    frame.command = "MESSAGE"
    dest = frame.headers['destination']
    @qstore.enqueue(dest,frame)
  end
end # of class
end # of module

