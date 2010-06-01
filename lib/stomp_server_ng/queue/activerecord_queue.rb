## Queue implementation using ActiveRecord
##
## all messages are stored in a single table
## they are indexed by 'stomp_id' which is the stomp 'message-id' header
## which must be unique accross all queues
##
require 'stomp_server_ng/queue/ar_message'
require 'yaml'

module StompServer
class ActiveRecordQueue
  attr_accessor :checkpoint_interval

  def initialize(configdir, storagedir, db_ymlfile)
    # Default configuration, use SQLite for simplicity
    db_params = {
      'adapter' => 'sqlite3',
      'database' => "#{configdir}/stompserver_development"
    }
    @@log = Logger::new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
    # Load DB configuration
    @@log.debug "trying to read from #{db_ymlfile}"
    if File.exists? db_ymlfile
      @@log.debug("File #{db_ymlfile} exists.")
      db_params.merge! YAML::load(File.open(db_ymlfile))
    else
      @@log.warn("File #{db_ymlfile} not found, using sqlite3 default.")
    end
    @@log.debug("using DB params: #{db_params.inspect}")
    # Setup activerecord
    ActiveRecord::Base.establish_connection(db_params)
    @@log.debug("connection complete")

    # AR Logger
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = StompServer::LogHelper.get_loglevel()

    # we need the connection, it can't be done earlier
    ArMessage.reset_column_information
    reload_queues
    @stompid = StompServer::StompId.new
  end

  # Add a frame to the queue
  def enqueue(queue_name, frame)
    unless @frames[queue_name]
      @frames[queue_name] = {
        :last_index => 0,
        :frames => [],
      }
    end
    affect_msgid_and_store(frame, queue_name)
    @frames[queue_name][:frames] << frame
  end

  # Get and remove a frame from the queue
  def dequeue(queue_name, session_id)
    return nil unless @frames[queue_name] && !@frames[queue_name][:frames].empty?
    frame = @frames[queue_name][:frames].shift
    remove_from_store(frame.headers['message-id'])
    return frame
  end

  # Requeue the frame previously pending
  def requeue(queue_name, frame)
    @frames[queue_name][:frames] << frame
    ArMessage.create!(:stomp_id => frame.headers['message-id'],
                      :frame => frame)
  end

  # remove a frame from the store
  def remove_from_store(message_id)
    ArMessage.find_by_stomp_id(message_id).destroy
  end

  # store a frame (assigning it a message-id)
  def affect_msgid_and_store(frame, queue_name)
    msgid = assign_id(frame, queue_name)
    ArMessage.create!(:stomp_id => msgid, :frame => frame)
  end

  def message_for?(queue_name, session_id)
    @frames[queue_name] && !@frames[queue_name][:frames].empty?
  end

  def assign_id(frame, queue_name)

    unless @frames[queue_name]
      @frames[queue_name] = {
        :last_index => 0,
        :frames => [],
      }
    end

    msgid = @stompid[@frames[queue_name][:last_index] += 1]
    frame.headers['message-id'] = msgid
  end

  private
  def reload_queues
    @frames = Hash.new
    ArMessage.find(:all).each { |message|
      frame = message.frame
      destination = frame.dest
      msgid = message.stomp_id
      @frames[destination] ||= Hash.new
      @frames[destination][:frames] ||= Array.new
      @frames[destination][:frames] << frame
    }
    # compute base index for each destination
    @frames.each_pair { |destination,hash|
      hash[:last_index] = hash[:frames].map{|f|
        f.headers['message-id'].match(/(\d+)\Z/)[0].to_i}.max
    }
  end
end
end
