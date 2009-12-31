#
#
#
module StompServer
#
# == Queue
#
class Queue
  # the check point interval
  attr_accessor :checkpoint_interval

  # initiialize
  def initialize(directory='.stompserver', delete_empty=true)

    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
    @@log.debug("Q #{self} initialization starts")

    @stompid = StompServer::StompId.new
    @delete_empty = delete_empty
    @directory = directory
    Dir.mkdir(@directory) unless File.directory?(@directory)
    if File.exists?("#{@directory}/qinfo")
      qinfo = Hash.new
      File.open("#{@directory}/qinfo", "rb") { |f| qinfo = Marshal.load(f.read)}
      @queues = qinfo[:queues]
      @frames = qinfo[:frames]
    else
      @queues = Hash.new
      @frames = Hash.new
    end

    @queues.keys.each do |dest|
      @@log.debug "Q  #{self} dest=#{dest} size=#{@queues[dest][:size]} enqueued=#{@queues[dest][:enqueued]} dequeued=#{@queues[dest][:dequeued]}" if $DEBUG
    end

    @@log.debug("Q #{self} initialized in #{@directory}")

    #
    # Cleanup dead queues and save the state of the queues every so often.  
    # Alternatively we could save the queue state every X number
    # of frames that are put in the queue.  
    # Should probably also read it after saving it to confirm integrity.
    #
    # Removed: this badly corrupts the queue when stopping with messages
    #
    # EventMachine::add_periodic_timer 1800, proc {@queues.keys.each 
    # {|dest| close_queue(dest)};save_queue_state }
    #
  end

  # stop
  def stop
    @@log.debug "#{self} Shutting down Queue"
    #
    @queues.keys.each {|dest| close_queue(dest)}
    @queues.keys.each do |dest|
      @@log.debug "Queue #{dest} size=#{@queues[dest][:size]} enqueued=#{@queues[dest][:enqueued]} dequeued=#{@queues[dest][:dequeued]}" if $DEBUG
    end
    save_queue_state
  end

  # save_queue_state
  def save_queue_state
    @@log.debug "#{self} save_queue_state"
    now=Time.now
    @next_save ||=now
    if now >= @next_save
      @@log.debug "Saving Queue State" if $DEBUG
      qinfo = {:queues => @queues, :frames => @frames}
      # write then rename to make sure this is atomic
      File.open("#{@directory}/qinfo.new", "wb") { |f| f.write Marshal.dump(qinfo)}
      File.rename("#{@directory}/qinfo.new","#{@directory}/qinfo")
      @next_save=now+checkpoint_interval
    end
  end

  # monitor
  def monitor
    @@log.debug "#{self} monitor"
    stats = Hash.new
    @queues.keys.each do |dest|
      stats[dest] = {'size' => @queues[dest][:size], 'enqueued' => @queues[dest][:enqueued], 'dequeued' => @queues[dest][:dequeued]}
    end
    stats
  end

  # close_queue
  def close_queue(dest)
    @@log.debug "#{self} close_queue"
    if @queues[dest][:size] == 0 and @queues[dest][:frames].size == 0 and @delete_empty
      _close_queue(dest)
      @queues.delete(dest)
      @frames.delete(dest)
      @@log.debug "Queue #{dest} removed." if $DEBUG
    end
  end

  # open_queue
  def open_queue(dest)
    @@log.debug "#{self} open_queue"
    @queues[dest] = Hash.new
    @frames[dest] = Hash.new
    @queues[dest][:size] = 0
    @queues[dest][:frames] = Array.new
    @queues[dest][:msgid] = 1
    @queues[dest][:enqueued] = 0
    @queues[dest][:dequeued] = 0
    @queues[dest][:exceptions] = 0
    _open_queue(dest)
    @@log.debug "Created queue #{dest}" if $DEBUG
  end

  # requeue
  def requeue(dest,frame)
    @@log.debug "#{self} requeue"
    open_queue(dest) unless @queues.has_key?(dest)
    msgid = frame.headers['message-id']
    if frame.headers['max-exceptions'] and @frames[dest][msgid][:exceptions] >= frame.headers['max-exceptions'].to_i
      enqueue("/queue/deadletter",frame)
      return
    end
    writeframe(dest,frame,msgid)
    @queues[dest][:frames].unshift(msgid)
    @frames[dest][msgid][:exceptions] += 1
    @queues[dest][:dequeued] -= 1
    @queues[dest][:exceptions] += 1
    @queues[dest][:size] += 1
    save_queue_state
    return true
  end

  # enqueue
  def enqueue(dest,frame)
    @@log.debug "#{self} enqueue"
    open_queue(dest) unless @queues.has_key?(dest)
    msgid = assign_id(frame, dest)
    @@log.debug("Enqueue for message: #{msgid} Client: #{frame.headers['client-id'] if frame.headers['client-id']}")
    writeframe(dest,frame,msgid)
    @queues[dest][:frames].push(msgid)
    @frames[dest][msgid] = Hash.new
    @frames[dest][msgid][:exceptions] =0
    @frames[dest][msgid][:client_id] = frame.headers['client-id'] if frame.headers['client-id']
    @frames[dest][msgid][:expires] = frame.headers['expires'] if frame.headers['expires']
    @queues[dest][:msgid] += 1
    @queues[dest][:enqueued] += 1
    @queues[dest][:size] += 1
    save_queue_state
    return true
  end

  # dequeue
  def dequeue(dest)
    @@log.debug "#{self} dequeue"
    return false unless message_for?(dest)
    msgid = @queues[dest][:frames].shift
    frame = readframe(dest,msgid)
    @@log.debug("Dequeue for message: #{msgid} Client: #{frame.headers['client-id'] if frame.headers['client-id']}")
    @queues[dest][:size] -= 1
    @queues[dest][:dequeued] += 1
    @queues[dest].delete(msgid)
    close_queue(dest)
    save_queue_state
    return frame
  end

  # messsage_for?
  def message_for?(dest)
    @@log.debug "#{self} message_for?"
    return (@queues.has_key?(dest) and (!@queues[dest][:frames].empty?))
  end

  # writeframe
  def writeframe(dest,frame,msgid)
    @@log.debug "#{self} writeframe"
    _writeframe(dest,frame,msgid)
  end

  # readframe
  def readframe(dest,msgid)
    @@log.debug "#{self} readframe"
    _readframe(dest,msgid)
  end

  # assign_id
  def assign_id(frame, dest)
    @@log.debug "#{self} assign_id"
    msg_id = @queues[dest].nil? ? 1 : @queues[dest][:msgid] 
    frame.headers['message-id'] = @stompid[msg_id] 
  end
end
end

