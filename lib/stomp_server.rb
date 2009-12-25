require 'rubygems'
require 'eventmachine'
require 'stomp_server/stomp_frame'
require 'stomp_server/stomp_id'
require 'stomp_server/stomp_auth'
require 'stomp_server/topic_manager'
require 'stomp_server/queue_manager'
require 'stomp_server/queue'
require 'stomp_server/queue/memory_queue'
require 'stomp_server/queue/file_queue'
require 'stomp_server/queue/dbm_queue'
require 'stomp_server/protocols/stomp'
require 'logger'

module StompServer
  VERSION = '0.9.9.2009.12.21.00'

  #
  # Ruby Logger Level Handler.
  #
  class LogHelper
    #
    # Set the desired logger level.
    #
    def self.set_loglevel(opts)
      @@loglevel = nil
      case opts[:log_level].downcase
        when 'debug' then @@loglevel = Logger::DEBUG
        when 'info'  then @@loglevel = Logger::INFO
        when 'warn'  then @@loglevel = Logger::WARN
        when 'error' then @@loglevel = Logger::ERROR
        else  
          @@loglevel = Logger::ERROR
      end
    end
    #
    # Return the desired logging level.
    #
    def self.get_loglevel
      @@loglevel
    end
    #
    # Display ruby version information on a defined logger output
    # destination.
    #
    def self.showversion(logger)
      # stompserver version
      logger.debug "stomp_server version: #{StompServer::VERSION}"
      # ruby version for all versions
      logger.debug "ruby: ver=#{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (reldate=#{RUBY_RELEASE_DATE})"
      # more ruby version information for 1.9+
      if RUBY_VERSION =~ /1.9/
        logger.debug "ruby: rev=#{RUBY_REVISION} engine=#{RUBY_ENGINE}"
      end
    end
    #
    # Clean logging of all options values.
    #
    def self.showoptions(logger, opts)
      logger.debug("Options Display Starts")
      # This is ugly, but it should only happen once at startup ......
      if RUBY_VERSION =~ /1.8/
        opts.keys.map {|key| key.to_s}.sort.each do |str_opt|
          optname = str_opt.to_sym
          logger.debug("Option: #{optname}=#{opts[optname]}")
        end
      else  # 1.9 version
        opts.keys.sort.each do |optname|
          logger.debug("Option: #{optname}=#{opts[optname]}")
        end
      end
      logger.debug("Options Display Ends")
    end
  end # of class LogHelper
  #
  # Module level configuration
  #
  class Configurator

    # The final options, merged from the defaults, the config file, and the 
    # command line.
    #--
    # Should this be 'read' only after construction ????
    attr_accessor :opts

    def initialize

      @opts = nil
      @defaults = {
        #
        # For clarity maintain the same order here as below in the 'getopts' 
        # method!!!!
        #
        :auth => false,                 # -a
        :host => "127.0.0.1",           # -b
        :checkpoint => 0,               # -c
        :config => 'stompserver.conf',  # -C
        :debug => false,                # -d
        :logdir => 'log',               # -D
        :log_level => 'error',          # -l
        :logfile => 'stompserver.log',  # -L
        :port => 61613,                 # -p
        :pidfile => 'stompserver.pid',  # -P
        :queue => 'memory',             # -q
        :storage => ".stompserver",     # -s
        :working_dir => Dir.getwd,      # -w
        :daemon => false                # -z
      }
      # Get a crude logger
      @@log = Logger.new(STDOUT)

      # Show version numbers regardless
      StompServer::LogHelper.showversion(@@log)

      # Options handling
      @opts = getopts()   # get and merge the options

      # Finalize logger level handling
      @@log.debug "Logger Level Requested: #{@opts[:log_level].upcase}"
      StompServer::LogHelper.set_loglevel(@opts)
      @@log.level = StompServer::LogHelper.get_loglevel()

      # Turn on $DEBUG for extra debugging info if requested
      if opts[:debug]
        $DEBUG=true
        @@log.debug "-d / --debug set, $DEBUG is true"
      end

      # Configuration is complete!
      @@log.info("#{self.class} Configuration complete")
    end

    def getopts()

      # New Options Parser
      opts_parser = OptionParser.new

      # Empty Hash for parser values
      hopts = {}

      # :auth
      opts_parser.on("-a", "--auth", String, 
        "Require client authorization") {|a| 
        hopts[:auth] = true}

      # :host
      opts_parser.on("-b", "--host=ADDR", String, 
        "Change the host (default: localhost)") {|a| 
        hopts[:host] = a}

      # :checkpoint
      opts_parser.on("-c", "--checkpoint=SECONDS", Integer, 
        "Time between checkpointing the queues in seconds (default: 0)") {|c| 
        hopts[:checkpoint] = c}

      # :config
      opts_parser.on("-C", "--config=CONFIGFILE", String, 
        "Configuration File (default: stompserver.conf)") {|c| 
        hopts[:config] = c}

      # :debug
      opts_parser.on("-d", "--debug", String, 
        "Turn on debug messages") {|d| 
        hopts[:debug] = true}

      # :logdir
      opts_parser.on("-D", "--logdir=LOGDIR", String, 
        "Log file directory  (default: log") {|d| 
        hopts[:logdir] = d} # new

      # :log_level
      opts_parser.on("-l", "--log_level=LEVEL", String, 
        "Logger Level (default: ERROR") {|l| 
        hopts[:log_level] = l}

      # :logfile
      opts_parser.on("-L", "--logfile=LOGFILE", String, 
        "Log file name (default: stompserver.log") {|l| 
        hopts[:logfile] = l} # new

      # :port
      opts_parser.on("-p", "--port=PORT", Integer, 
        "Change the port (default: 61613)") {|p| 
        hopts[:port] = p}

      # :pidfile
      opts_parser.on("-P", "--pidfile=PIDFILE", Integer, 
        "PID file name (default: stompserver.pid)") {|p| 
        hopts[:pidfile] = p} # new

      # :queue
      opts_parser.on("-q", "--queuetype=QUEUETYPE", String, 
        "Queue type (memory|dbm|activerecord|file) (default: memory)") {|q| 
        hopts[:queue] = q}

      # :storage
      opts_parser.on("-s", "--storage=DIR", String, 
        "Change the storage directory (default: .stompserver, relative to working_dir)") {|s| 
        hopts[:storage] = s}

      # :working_dir
      opts_parser.on("-w", "--working_dir=DIR", String, 
        "Change the working directory (default: current directory)") {|s| 
        hopts[:working_dir] = s}

      # :daemon
      opts_parser.on("-z", "--daemon", String, 
        "Daemonize server process") {|d| 
        hopts[:daemon] = true}

      # Handle help if required
      opts_parser.on("-h", "--help", "Show this message") do
        puts opts_parser
        exit
      end

      opts_parser.parse(ARGV)

      # Handle the config file
      loaded_opts = {}
      if hopts[:config]
        @@log.debug("Config file is: #{hopts[:config]}")
        loaded_opts = YAML.load_file(hopts[:config])
      elsif File.exists?(@defaults[:config])
        @@log.debug("Config file is: #{@defaults[:config]}")
        loaded_opts = YAML.load_file(@defaults[:config])
      else
        @@log.warn("Config file not found")
      end

      # Run basic required merges on all the options
      opts = {}                         # set to empty
      opts = opts.merge(@defaults)      # 01 = merge in defaults
      opts = opts.merge(loaded_opts)    # 02 = merge in loaded from config file
      opts = opts.merge(hopts)          # 03 = merge in command line options

      # Last but not least: Miscellaneous file definitions
      opts[:etcdir] = File.join(opts[:working_dir],'etc')           # Define ':etcdir'
      opts[:storage] = File.join(opts[:working_dir],opts[:storage]) # Override! ':storage'
      opts[:logdir] = File.join(opts[:working_dir],opts[:logdir])   # Override! ':logdir'
      opts[:logfile] = File.join(opts[:logdir],opts[:logfile])      # Override! ':logfile'
      opts[:pidfile] = File.join(opts[:logdir],opts[:pidfile])      # Override! ':pidfile'

      # Authorization - working file
      if opts[:auth]
        opts[:passwd] = File.join(opts[:etcdir],'.passwd')
      end
      
      # Return merged values (in Hash)
      return opts
    end
  end

  #
  # Run the server.
  #
  class Run
    attr_accessor :queue_manager, :auth_required, :stompauth, :topic_manager

    # Intiialize
    def initialize(opts)
      @@log = Logger.new(STDOUT)
      @@log.level = StompServer::LogHelper.get_loglevel()

      @opts = opts
      @queue_manager = nil
      @auth_required = nil
      @stompauth = nil
      @topic_manager = nil
      @@log.info("#{self.class} Run class initialize complete")
    end

    # Server stop on SIGINT
    def stop(pidfile)
      @queue_manager.stop
      @@log.debug "Stompserver #{StompServer::VERSION} shutting down"
      STDOUT.flush
      EventMachine::stop_event_loop
      File.delete(pidfile)
    end

    # Startup
    def start
      @@log.info("#{self.class}.start begins")

      # Handle group priviliges!
      # N.B.: Handle these options from the command line ?????????
      begin
        if @opts[:group]
          @@log.debug "Changing group to #{@opts[:group]}."
          Process::GID.change_privilege(Etc.getgrnam(@opts[:group]).gid)
        end

        if @opts[:user]
          @@log.debug "Changing user to #{@opts[:user]}."
          Process::UID.change_privilege(Etc.getpwnam(@opts[:user]).uid)
        end
      rescue Errno::EPERM
        @@log.error "FAILED to change user:group #{@opts[:user]}:#{@opts[:group]}: #$!"
        exit 1
      end

      # Make required directories unless they already exist
      Dir.mkdir(@opts[:working_dir]) unless File.directory?(@opts[:working_dir])
      Dir.mkdir(@opts[:logdir]) unless File.directory?(@opts[:logdir])
      Dir.mkdir(@opts[:etcdir]) unless File.directory?(@opts[:etcdir])

      # Write pidfile
      open(@opts[:pidfile],"w") {|f| f.write(Process.pid) }

      # Determine qstore type
      if @opts[:queue] == 'dbm'
        qstore=StompServer::DBMQueue.new(@opts[:storage])
        @@log.info "Queue storage is DBM"
      elsif @opts[:queue] == 'file'
        qstore=StompServer::FileQueue.new(@opts[:storage])
        @@log.info "Queue storage is FILE"
      elsif @opts[:queue] == 'activerecord'
        require 'stomp_server/queue/activerecord_queue'
        qstore=StompServer::ActiveRecordQueue.new(@opts[:etcdir], @opts[:storage])
        @@log.info "Queue storage is ActiveRecord"
      else
        qstore=StompServer::MemoryQueue.new
        @@log.info "Queue storage is MEMORY"
      end

      # Set checkpoint interval
      qstore.checkpoint_interval = @opts[:checkpoint]
      @@log.debug "Checkpoint interval is #{qstore.checkpoint_interval}" if $DEBUG

      #
      @topic_manager = StompServer::TopicManager.new
      @queue_manager = StompServer::QueueManager.new(qstore)
      @@log.debug("Managers are initialized.")
      @@log.debug("Topic Manager: #{@topic_manager}")
      @@log.debug("Queue Manager: #{@queue_manager}")

      # Authorization: requirement
      @auth_required = @opts[:auth]
      if @auth_required
        @stompauth = StompServer::StompAuth.new(@opts[:passwd])
      end

      # If we are going to daemonize, it should be about the last
      # thing we do here.
      @@log.info("#{self.class}.start Daemonize: #{@opts[:daemon]}")
      if @opts[:daemon]
        @@log.debug("#{self.class}.start going to background")
        @@log.debug("#{self.class}.start check #{@opts[:logfile]}")

        StompServer::LogHelper.showversion(@@log)

        STDOUT.flush    # clear the decks
        Daemonize.daemonize(log_file=@opts[:logfile])
        # change back to the original starting directory
        Dir.chdir(@opts[:working_dir])
      end

      # OK, so no daemon: log and set the SIGINT signal handler.
      @@log.info("#{self.class}.start setting trap at completion")
      StompServer::LogHelper.showversion(@@log) # one more time at startup
      StompServer::LogHelper.showoptions(@@log, @opts) # Dump runtime options
      trap("INT") { @@log.debug "INT signal received.";stop(@opts[:pidfile]) }
    end
  end # of class Run
#
end # of module StompServer

