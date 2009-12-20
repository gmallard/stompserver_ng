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
  VERSION = '0.9.9.2009121900'

  class LogLevelHandler
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
    def self.get_loglevel
      @@loglevel
    end
  end

  class Configurator
    attr_accessor :opts

    def initialize

      @opts = nil
      @defaults = {
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
      #
      @@log = Logger.new(STDOUT)
      @@log.debug "stomp_server version: #{StompServer::VERSION}"
      @@log.debug "ruby: ver=#{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (reldate=#{RUBY_RELEASE_DATE})"
      if RUBY_VERSION =~ /1.9/
        @@log.debug "ruby: rev=#{RUBY_REVISION} engine=#{RUBY_ENGINE}"
      end

      @opts = getopts   # get the options
      @@log.debug "Logger Level Requested: #{@opts[:log_level].upcase}"
      StompServer::LogLevelHandler.set_loglevel(@opts)
      @@log.level = StompServer::LogLevelHandler.get_loglevel()
      #
      if opts[:debug]
        $DEBUG=true
        @@log.debug "-d / --debug set, $DEBUG is true"
      end
      @@log.info("#{self.class} Configuration complete")
    end

    def getopts
      opts_parser = OptionParser.new
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

      #
      opts_parser.on("-h", "--help", "Show this message") do
        puts opts_parser
        exit
      end

      opts_parser.parse(ARGV)

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

      opts = {}
      opts = opts.merge(@defaults)
      opts = opts.merge(loaded_opts)
      opts = opts.merge(hopts)

      opts[:etcdir] = File.join(opts[:working_dir],'etc')
      opts[:storage] = File.join(opts[:working_dir],opts[:storage])
      opts[:logdir] = File.join(opts[:working_dir],opts[:logdir])
      opts[:logfile] = File.join(opts[:logdir],opts[:logfile])
      opts[:pidfile] = File.join(opts[:logdir],opts[:pidfile])
      if opts[:auth]
        opts[:passwd] = File.join(opts[:etcdir],'.passwd')
      end

      return opts
    end
  end


  class Run
    attr_accessor :queue_manager, :auth_required, :stompauth, :topic_manager

    def initialize(opts)
      @@log = Logger.new(STDOUT)
      @@log.level = StompServer::LogLevelHandler.get_loglevel()

      @opts = opts
      @queue_manager = nil
      @auth_required = nil
      @stompauth = nil
      @topic_manager = nil
      @@log.info("Run initialize complete")
    end

    def stop(pidfile)
      @queue_manager.stop
      @@log.debug "Stompserver #{StompServer::VERSION} shutting down"
      STDOUT.flush
      EventMachine::stop_event_loop
      File.delete(pidfile)
    end

    def start
      @@log.info("#{self.class}.start begins")
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

      Dir.mkdir(@opts[:working_dir]) unless File.directory?(@opts[:working_dir])
      Dir.mkdir(@opts[:logdir]) unless File.directory?(@opts[:logdir])
      Dir.mkdir(@opts[:etcdir]) unless File.directory?(@opts[:etcdir])

      @@log.info("#{self.class}.start Daemonize: #{@opts[:daemon]}")
      if @opts[:daemon]
        Daemonize.daemonize(log_file=@opts[:logfile])
        # change back to the original starting directory
        Dir.chdir(@opts[:working_dir])
      end

      # Write pidfile
      open(@opts[:pidfile],"w") {|f| f.write(Process.pid) }

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

      qstore.checkpoint_interval = @opts[:checkpoint]
      @@log.debug "Checkpoint interval is #{qstore.checkpoint_interval}" if $DEBUG
      @topic_manager = StompServer::TopicManager.new
      @queue_manager = StompServer::QueueManager.new(qstore)

      @auth_required = @opts[:auth]
      if @auth_required
        @stompauth = StompServer::StompAuth.new(@opts[:passwd])
      end

      @@log.info("#{self.class}.start setting trap at completion")
      trap("INT") { @@log.debug "INT signal received.";stop(@opts[:pidfile]) }
    end
  end
#

end

