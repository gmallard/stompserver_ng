require 'logger'
$:.unshift File.dirname(__FILE__)
require 'mocklogger'
#
require 'stomp_server/topic_manager'
require 'test/unit' unless defined? $ZENTEST and $ZENTEST

class TestTopics < Test::Unit::TestCase

  class UserMock
    attr_accessor :data
    def initialize ; @data = '' ; end
    def stomp_send_data(data); @data += data.to_s ; end
  end
  
  class MessageMock
    attr_accessor :headers, :data, :command
    def initialize(dest, msg)  
      @headers = { 'destination' => dest }
      @data = msg
    end
    def to_s ; @data ; end
  end
  
  def setup
    @t = StompServer::TopicManager.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
  end
    
  def test_subscribe
    @log.debug("test_subscribe starts")
    u = UserMock.new
    t = 'foo'
    @t.subscribe(t, u)
    
    m1 = MessageMock.new('foo', 'foomsg')
    m2 = MessageMock.new('bar', 'barmsg')
    @t.sendmsg(m1)
    assert_equal(m1.data, u.data)
    
    u.data = ''
    @t.sendmsg(m2)
    assert_equal('', u.data)
    @log.debug("test_subscribe ends")
  end

  def test_unsubscribe
    @log.debug("test_unsubscribe starts")
    u = UserMock.new
    t = 'foo'
    @t.subscribe(t, u)
    
    m1 = MessageMock.new('foo', 'foomsg')
    @t.sendmsg(m1)
    assert_equal(m1.data, u.data)

    @t.unsubscribe(t,u)
    u.data = ''
    @t.sendmsg(m1)
    assert_equal('', u.data)        
    @log.debug("test_unsubscribe ends")
  end

  def test_sendmsg
    @log.debug("test_sendmsg starts")
    u = UserMock.new
    t = 'foo'
    @t.subscribe(t, u)
    
    m1 = MessageMock.new('foo', 'foomsg')
    @t.sendmsg(m1)
    assert_equal(m1.data, u.data)
    assert_equal('MESSAGE', m1.command)
    @log.debug("test_sendmsg ends")
  end

end

