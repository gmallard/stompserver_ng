require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0015_Ack_Conn < Test_0000_Base

  def setup
    super
    open_conn()
    @queuename = "/queue/connack"
    @test_message = "What's up doc?"
    #
  end

  #
  def teardown
    disconnect_conn()
  end

  # Test ACK of a single message
  def test_0010_ack_conn_one
    #
    received = nil
    assert_nothing_raised() {
      @conn.send(@queuename, @test_message)
      #
      subscribe(@queuename, { "ack" => "client" })
      received = @conn.receive 
    }
    #
    assert_not_nil(received, "something should be received")
    assert_equal(@test_message, received.body, "received should match sent")
    #
    assert_not_nil(received.headers["message-id"], "message ID should be present")
    assert_nothing_raised() {
      @conn.ack(received.headers["message-id"]) 
    }
  end

  # Make sure that connect still works.
  def test_0099_ack_conn_last
    assert_not_nil(@conn, "connection should not be nil")
  end

end # of class

