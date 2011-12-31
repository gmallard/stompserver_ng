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
        @@log.debug "Q #{self} dest=#{dest} size=#{@queues[dest][:size]} enqueued=#{@queues[dest][:enqueued]} dequeued=#{@queues[dest][:dequeued]}"
      end
      @@log.debug("Q #{self} initialized in #{@directory}")
    end

    # stop
    def stop(session_id)
      @@log.debug "#{session_id} Shutting down Queues, queue count: #{@queues.size}"
      #
      @queues.keys.each do |dest|
        @@log.debug "#{session_id}: Queue #{dest}: size=#{@queues[dest][:size]} enqueued=#{@queues[dest][:enqueued]} dequeued=#{@queues[dest][:dequeued]}"
        close_queue(dest, session_id)
      end
      save_queue_state(session_id)
    end

    # save_queue_state
    def save_queue_state(session_id)
      @@log.debug "#{session_id} save_queue_state"
      now=Time.now
      @next_save ||=now
      if now >= @next_save
        @@log.debug "#{session_id} saving state"
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
        stats[dest] = { 
          'size'        => @queues[dest][:size], 
          'enqueued'    => @queues[dest][:enqueued], 
          'dequeued'    => @queues[dest][:dequeued],
          'exceptions'  => @queues[dest][:exceptions],
        }
      end
      stats
    end

    # close_queue
    def close_queue(dest, session_id)
      @@log.debug "#{session_id} close_queue #{dest}"
      if @queues[dest][:size] == 0 and @queues[dest][:frames].size == 0 and @delete_empty
        _close_queue(dest)
        @queues.delete(dest)
        @frames.delete(dest)
        @@log.debug "#{session_id} Queue #{dest} removed."
      end
    end

    # open_queue
    def open_queue(dest, session_id)
      @@log.debug "#{session_id} open_queue #{dest}"
      # New queue
      @queues[dest] = Hash.new
      # New frames for this queue
      @frames[dest] = Hash.new
      # Update queues
      # :size, :frames, :msgid, :enqueued, :dequeued, :exceptions
      @queues[dest][:size] = 0
      @queues[dest][:frames] = Array.new
      @queues[dest][:msgid] = 1
      @queues[dest][:enqueued] = 0
      @queues[dest][:dequeued] = 0
      @queues[dest][:exceptions] = 0
      _open_queue(dest)
      @@log.debug "#{session_id} created queue #{dest}"
    end

    # requeue
    def requeue(dest,frame)
      @@log.debug "#{frame.headers['session']} requeue, for #{dest}, frame: #{frame.inspect}"
      open_queue(dest, frame.headers['session']) unless @queues.has_key?(dest)
      msgid = frame.headers['message-id']
      #
      writeframe(dest,frame,msgid)
      # update queues (queues[dest])
      # :size, :frames, :msgid, :enqueued, :dequeued, :exceptions
      @queues[dest][:size] += 1
      @queues[dest][:frames].unshift(msgid)
      # no :msgid here
      # no :enqueued here
      # no :dequeued here
      @queues[dest][:exceptions] += 1

      # update frames
      #
      # Is this _always_ the case in this method ?????
      unless @frames[dest][msgid]
        new_frames_entry(dest, frame, msgid)
      end
      #
      @frames[dest][msgid][:exceptions] += 1
      @frames[dest][msgid][:requeued] += 1
      save_queue_state(frame.headers['session'])
      return true
    end

    # enqueue
    def enqueue(dest,frame)
      @@log.debug "#{frame.headers['session']} enqueue  #{dest}"
      open_queue(dest, frame.headers['session']) unless @queues.has_key?(dest)
      msgid = assign_id(frame, dest)
      @@log.debug("#{frame.headers['session']} Enqueue for #{dest} for message: #{msgid} Client: #{frame.headers['client-id'] if frame.headers['client-id']}")
      writeframe(dest,frame,msgid)

      # update queues (queues[dest])
      # :size, :frames, :msgid, :enqueued, :dequeued, :exceptions
      @queues[dest][:size] += 1
      @queues[dest][:frames].push(msgid)
      @queues[dest][:msgid] += 1
      @queues[dest][:enqueued] += 1
      # no :dequeue here
      # no :exceptions here

      # Update frames
      # Initialize frames entry for this: dest, frame, and msgid
      new_frames_entry(dest, frame, msgid)
      save_queue_state(frame.headers['session'])
      return true
    end

    # dequeue
    def dequeue(dest, session_id)
      @@log.debug "#{session_id} dequeue, dest: #{dest}"
      return false unless message_for?(dest, session_id)
      # update queues ... dest .... :frames here
      msgid = @queues[dest][:frames].shift
      frame = readframe(dest,msgid,session_id)
      @@log.debug("#{frame.headers['session']} Dequeue for message: #{msgid} Client: #{frame.headers['client-id'] if frame.headers['client-id']}")

      # update queues (queues[dest])
      # :size, :frames, :msgid, :enqueued, :dequeued, :exceptions
      @queues[dest][:size] -= 1
      # :frames - see above
      @queues[dest][:msgid] -= 1
      # :enqueued - no change
      @queues[dest][:dequeued] += 1
      # :exceptions - no change

      @queues[dest].delete(msgid)

      close_queue(dest, frame.headers['session'])
      save_queue_state(frame.headers['session'])
      return frame
    end

    # messsage_for?
    def message_for?(dest, session_id)
      retval = (@queues.has_key?(dest) and (!@queues[dest][:frames].empty?))
      @@log.debug "#{session_id} message_for?, dest: #{dest}, #{retval}"
      return retval
    end

    # writeframe
    def writeframe(dest,frame,msgid)
      @@log.debug "#{frame.headers['session']} writeframe, dest: #{dest}, frame: #{frame}, msgid: #{msgid}"
      _writeframe(dest,frame,msgid)
    end

    # readframe
    def readframe(dest,msgid, session_id)
      @@log.debug "#{session_id} readframe, dest: #{dest}, msgid: #{msgid}"
      _readframe(dest,msgid)
    end

    # assign_id
    def assign_id(frame, dest)
      @@log.debug "#{frame.headers['session']} assign_id, frame: #{frame}, dest: #{dest}"
      msg_id = @queues[dest].nil? ? 1 : @queues[dest][:msgid] 
      frame.headers['message-id'] = @stompid[msg_id] 
    end

    private
    # new_frames_entry
    def new_frames_entry(dest, frame, msgid)
      @frames[dest][msgid] = Hash.new
      @frames[dest][msgid][:exceptions] = 0
      @frames[dest][msgid][:requeued] = 0
      @frames[dest][msgid][:client_id] = frame.headers['client-id'] if frame.headers['client-id']
      @frames[dest][msgid][:expires] = frame.headers['expires'] if frame.headers['expires']
    end
  #
  end # class Queue
#
end # module StompServer

