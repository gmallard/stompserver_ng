
module StompServer
class StompFrame
  attr_accessor :command, :headers, :body
  def initialize(command=nil, headers=nil, body=nil)
    @command = command
    @headers = headers || {}
    @body = body || ''
    #
    @@log = Logger.new(STDOUT)
    @@log.level = StompServer::LogHelper.get_loglevel()
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
end

