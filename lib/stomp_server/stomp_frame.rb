
module StompServer
class StompFrame
  attr_accessor :command, :headers, :body
  def initialize(command=nil, headers=nil, body=nil)
    @command = command
    @headers = headers || {}
    @body = body || ''
    #
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogLevelHandler.get_loglevel()
  end
 
  def to_s
    result = @command + "\n"
    # 1.8 / 1.9 compat
    @headers['content-length'] = @body.size.to_s if @body.include?(0.chr)
    @headers.each_pair do |key, value|
      result << "#{key}:#{value}\n"
    end
    result << "\n"
    result << @body.to_s
    result << "\000\n"  
  end
  
  def dest
    #@dest || (@dest = @headers['destination'])
    @headers['destination']
  end
end


class StompFrameRecognizer
  attr_accessor :frames
  
  def initialize
    @buffer = ''
    @body_length = nil
    @frame = StompServer::StompFrame.new
    @frames = []
    #
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogLevelHandler.get_loglevel
  end
  
  def parse_body(len)
    # 1.8 / 1.9 compat 
    raise RuntimeError.new("Invalid stompframe (missing null term)") unless @buffer[len].to_i == 0
    @frame.body = @buffer[0...len]
    @buffer = @buffer[len+1..-1]
    @frames << @frame
    @frame = StompServer::StompFrame.new
  end
  
  def parse_binary_body
    if @buffer.length > @body_length
      parse_body(@body_length)
    end
  end
  
  def parse_text_body
    @@log.debug("StompFrameRecognizer parse_text_body starts")
    pos = @buffer.index(0.chr)  # 1.8 / 1.9 compat
    if pos
      parse_body(pos)
    end
  end
  
  def parse_header
    if match = @buffer.match(/^\s*(\S+)$\r?\n((?:[ \t]*.*?[ \t]*:[ \t]*.*?[ \t]*$\r?\n)*)\r?\n/)
      @frame.command, headers = match.captures
      @buffer = match.post_match
      headers.split(/\n/).each do |data|
        if data =~ /^\s*(\S+)\s*:\s*(.*?)\s*$/
          @frame.headers[$1] = $2
        end
      end
      
      # body_length is nil, if there is no content-length, otherwise it is the length (as in integer)
      @body_length = @frame.headers['content-length'] && @frame.headers['content-length'].to_i
    end
  end
  
  def parse
    count = @frames.size
    
    parse_header unless @frame.command
    if @frame.command
      if @body_length
        parse_binary_body
      else
        parse_text_body
      end
    end
    
    # parse_XXX_body return the frame if they succeed and nil if they fail
    # the result will fall through
    parse if count != @frames.size
  end
  
  def<< (buf)
    @buffer << buf
    parse
  end    
end
end
