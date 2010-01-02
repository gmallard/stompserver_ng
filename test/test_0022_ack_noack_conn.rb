require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0022_Ack_Noack_Conn < Test_0000_Base

  def setup
    super
    open_conn()
    @queuename = "/queue/connana1"
    @test_message = "Blue Suede Shoes ..."
    #
  end

  #
  def teardown
    disconnect_conn()
  end

  # Test missing ACK of a message ID
  def test_0010_ack_conn_no_ack
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
    # Do nothing, just let teardown issue the disconnect.
    # Expected: no failures, and server does not crash.
    #
  end

end # of class

