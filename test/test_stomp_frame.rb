require 'logger'
$:.unshift File.dirname(__FILE__)
require 'mocklogger'
require 'stomp_server/stomp_frame'
require 'test/unit' unless defined? $ZENTEST and $ZENTEST

class TestStompFrame < Test::Unit::TestCase
  def setup
    @sfr = StompServer::StompFrameRecognizer.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
  end
  
  def test_simpleframe
    @log.debug("test_simpleframe starts")
    @sfr << <<FRAME
COMMAND
name:value
foo:bar

message body
\000
FRAME
    assert_equal(1, @sfr.frames.size)
    f = @sfr.frames.shift
    assert_equal(0, @sfr.frames.size)
    assert_equal("COMMAND", f.command)
    assert_equal("value", f.headers["name"])
    assert_equal("bar", f.headers["foo"])
    assert_equal("message body\n", f.body)
    @log.debug("test_simpleframe ends")
  end
  
  def test_doubleframe
    @log.debug("test_doubleframe starts")
    @sfr << <<FRAME
COMMAND
name:value
foo:bar

message body
\000

COMMAND2
name2:value2
foo2:bar2

message body 2
\000
FRAME
    assert_equal(2, @sfr.frames.size)
    f = @sfr.frames.shift
    assert_equal(1, @sfr.frames.size)
    assert_equal("COMMAND", f.command)
    assert_equal("value", f.headers["name"])
    assert_equal("bar", f.headers["foo"])
    assert_equal("message body\n", f.body)
    
    # check second frame
    f = @sfr.frames.shift
    assert_equal(0, @sfr.frames.size)
    assert_equal("COMMAND2", f.command)
    assert_equal("value2", f.headers["name2"])
    assert_equal("bar2", f.headers["foo2"])
    assert_equal("message body 2\n", f.body)
    @log.debug("test_doubleframe ends")
  end
  
    def test_partialframe
    @log.debug("test_partialframe starts")
    @sfr << <<FRAME
COMMAND
name:value
foo:bar

message body
\000

COMMAND2
name2:value2
foo2:bar2

message body 2
FRAME
    assert_equal(1, @sfr.frames.size)
    f = @sfr.frames.shift
    assert_equal(0, @sfr.frames.size)
    assert_equal("COMMAND", f.command)
    assert_equal("value", f.headers["name"])
    assert_equal("bar", f.headers["foo"])
    assert_equal("message body\n", f.body)    
    @log.debug("test_partialframe ends")
  end

  def test_partialframe2
    @log.debug("test_partialframe2 starts")
    @sfr << <<FRAME
COMMAND
name:value
foo:bar
FRAME
    assert_equal(0, @sfr.frames.size)
    @log.debug("test_partialframe2 ends")
  end
  
  def test_headless_frame
    @log.debug("test_headless_frame starts")
    @sfr << <<FRAME
COMMAND

message body\000
FRAME
    assert_equal(1, @sfr.frames.size)
    f = @sfr.frames.shift
    assert_equal(0, @sfr.frames.size)
    assert_equal("COMMAND", f.command)
    assert_equal("message body", f.body)
    @log.debug("test_headless_frame ends")
  end

  def test_destination_cache
    @log.debug("test_destination_cache starts")
    @sfr << <<FRAME
MESSAGE
destination: /queue/foo

message body\000
FRAME
    assert_equal(1, @sfr.frames.size)
    f = @sfr.frames.shift
    assert_equal(0, @sfr.frames.size)
    assert_equal("MESSAGE", f.command)
    assert_equal("message body", f.body)
    assert_equal('/queue/foo', f.dest)    
    @log.debug("test_destination_cache ends")
  end  
end

