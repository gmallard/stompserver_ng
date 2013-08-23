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
  Struct::new('QueueUser', :connection, :ack, :subid, :pending)
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
    user = Struct::QueueUser.new(connection, use_ack, subid, nil)
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
  def send_a_backlog(user)
    connection = user.connection
    @@log.debug "#{connection.session_id} QM send_a_backlog starts"

    # Since pending is queue-based, we only need to try to send a message to the
    # queue for the user that the 'ack'd message was sent to.
    # Unfortunately we don't know what that was.  We DO however know the 'user'
    # that it was sent to, and we can look up the queues to locate the one that has
    # this user linked to it (connection + subscription are unique, so there can
    # be only one user record for this connection connected to a given queue)
    dest = @queues.map { |dest, users| users.find_index(user) ? dest : nil }.compact.first

    @@log.debug "#{connection.session_id} QM s_a_b chosen -> dest: #{dest}"

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
    msgid = frame.headers['message-id']
    user = get_user_for_msgid(connection, msgid)

    unless user
      @@log.debug "#{connection.session_id} QM No message pending for msgid #{msgid}!"
      return
    end

    user.pending = nil

    # We are free to work now, look if there's something for us
    send_a_backlog(user)
  end
  #
  # Client disconnect.
  #
  # Called from the protocol handler (unbind method).
  #
  def disconnect(connection)
    @@log.debug("#{connection.session_id} QM DISCONNECT.")
    users = get_users_for_connection(connection)
    if users && !users.empty?
      users.each { |u|
        if u.pending
          @@log.debug("#{connection.session_id} QM DISCONNECT pending frame: #{u.pending.inspect}")
          @qstore.requeue(u.pending.headers['destination'], u.pending)
          u.pending = nil
        end
      }
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
    unless frame
      @@log.debug("#{user.connection.session_id} QM s_t_u No message to send")
      return
    end

    connection = user.connection
    frame.headers['subscription'] = user.subid if user.subid
    if user.ack
      # raise on internal logic error.
      raise "#{user.connection.session_id} other connection's end already busy" if user.pending
      # A maximum of one frame can be pending ACK per subscription/connection.
      user.pending = frame
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
    # Lookup a user willing to handle this destination, and aren't waiting for an ACK
    available_users = @queues[dest].reject{|user| user.pending}
    if available_users.empty?
      @@log.debug("#{frame.headers['session']} QM sendmsg queuing #{frame}")
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
  #
  # get_user_for_msgid: Attempts to find a user that is waiting for an ACK on a given msgid
  #
  def get_user_for_msgid(connection, msgid)
    # There should only be one match, so lets just return it
    return @queues.values.flatten.select {|u| u.connection == connection && u.pending && u.pending.headers['message-id'] == msgid }.first
  end
  #
  # get_users_for_connection: Returns all users associated with this connection (session-id)
  #
  def get_users_for_connection(connection)
    return @queues.values.flatten.select {|u| u.connection == connection}
  end
end # of class
end # of module

