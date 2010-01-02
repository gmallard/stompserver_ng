require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0024_Ack_Noack_Reconn_Ack < Test_0000_Base

  def setup
    super
    @queuename = "/queue/connana3"
    @test_message = "A Country Boy Can Survive ..."
    #
    @reconnect_stagger = 1
  end

  #
  def teardown
  end

  # Test missing ACK of a message ID
  def test_0010_ack_conn_no_ack
    open_conn()
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
    #
    disconnect_conn()
    #
    sleep @reconnect_stagger  # Let server clean up
    open_conn()
    received_02 = nil
    assert_nothing_raised() {
      subscribe(@queuename, { "ack" => "client" })
      received_02 = @conn.receive 
    }
    #
    assert_not_nil(received_02, "something should be received")
    assert_equal(@test_message, received_02.body, "received should again match sent")
    assert_not_nil(received_02.headers["message-id"], "message ID should be present")
    #
    assert_nothing_raised() {
      @conn.ack(received_02.headers["message-id"])
    }
    #
    disconnect_conn()
  end

end # of class

