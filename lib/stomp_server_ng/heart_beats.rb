#
# Stomp 1.1+ Heartbeat support
#
module StompServer
  #
  # Implement heartbeating if required
  #
  class HeartBeats
    #
    attr_reader :cx, :cy, :sx, :sy # see the 1.1 specification ....
    #
    attr_reader :sti, :rti # ticker intervals
    #
    attr_accessor :ls, :lr # last send/receive time (a Float)
    #
    attr_reader :st, :rt # send/receive thread references
    #
    attr_reader :hbs, :hbr # booleans: sending/receiving
    #
    attr_reader :hb_received # receive 'dirty' flag
    #
    def initialize(cliparms, svrparms, conn, flog = false)
      #
      @@log = Logger.new(STDOUT)
      @@log.level = StompServer::LogHelper.get_loglevel()
      #
      @connection = conn
      @firelog = flog
      @hb_received = true # We just now got a CONNECT frame here .....
      #
      @cx = @cy = @sx = @sy = 0, # Variable names as in spec
      #
      @sti = @rti = 0.0 # Send/Receive ticker interval.
      #
      @ls = @lr = -1.0 # Last send/receive time (from Time.now.to_f)
      #
      @st = @rt = nil # Send/receive ticker thread
      #
      parts = cliparms.split(",")
      @cx = parts[0].to_i
      @cy = parts[1].to_i
      parts = svrparms.split(",")
      @sx = parts[0].to_i
      @sy = parts[1].to_i
      #
      @hbs = @hbr = true # Sending/Receiving heartbeats. Assume yes at first.

      # Check for sending (N.B. - server logic for these checks)
      @hbs = false if @sx == 0 || @cy == 0
      # Check for receiving
      @hbr = false if @cx == 0 || @sy == 0
      # If sending
      if @hbs
        sm = @sx >= @cy ? @sx : @cy # ticker interval, ms
        @sti = 1000.0 * sm          # ticker interval, μs
        @ls = Time.now.to_f         # best guess at start
        _start_send_ticker
      end
      # If receiving
      if @hbr
        rm = @cx >= @sy ? @cx : @sy # ticker interval, ms
        @rti = 1000.0 * rm          # ticker interval, μs
        @lr = Time.now.to_f         # best guess at start
        _start_receive_ticker
      end

    end

    private

    def _start_send_ticker
      @@log.debug("#{@connection.session_id} send ticker start: #{@sti}")
      sleeptime = @sti / 1000000.0 # Sleep time secs
      @st = Thread.new {
        while true do
          sleep sleeptime
          curt = Time.now.to_f
          @@log.warn("#{@connection.session_id} send ticker fire: #{curt}") if @firelog
          delta = curt - @ls
          if delta > (@sti - (@sti/5.0)) / 1000000.0 # Be tolerant (minus)
            # Send a heartbeat
            @@log.warn("#{@connection.session_id} send ticker sending a heart beat")
            @connection.send_data(StompServer::HEART_BEAT)
            @ls = Time.now.to_f
          end
          Thread.pass
        end
      }
    end

    def _start_receive_ticker
      @@log.debug("#{@connection.session_id} receive ticker start: #{@rti}")
      sleeptime = @rti / 1000000.0 # Sleep time secs
      @rt = Thread.new {
        while true do
          sleep sleeptime
          curt = Time.now.to_f
          @@log.warn("#{@connection.session_id} receive ticker fire: #{curt}") if @firelog
          delta = curt - @lr
          if delta > ((@rti + (@rti/5.0)) / 1000000.0) # Be tolerant (plus)
            @hb_received = false # Flag bad
            @@log.warn("#{@connection.session_id} receive ticker missed heartbeat: #{@lr}")
          else
            unless @hb_received
              @hb_received = true # Reset if necessary
              @@log.warn("#{@connection.session_id} receive ticker next pass reset")
            end
          end
          Thread.pass
        end
      }
    end

  end
end

