require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test situations with a Stomp Connection where ack mode is specified on a 
# connection_subscribe, but the message is initially never actually ACK'd.
#
#
class Test_0022_Ack_Noack_Conn < Test_0000_Base

  # Setup.
  # * Queue name
  # * Message body
  # * Connect stagger/reconnect wait time
  def setup
    super
    open_conn()
    @queuename = "/queue/connana1/" + name()
    @test_message = "Blue Suede Shoes ..."
    @reconnect_stagger = 0.5
    #
  end

  # Teardown.
  def teardown
    disconnect_conn()
  end

  # Test Ack Conn No Ack:
  # * Send a messsage
  # * Subscribe with ack, and receive
  # * Never send an ACK
  # Expectation: no client errors, and no server crashes.
  def test_0010_ack_conn_no_ack
    no_ack_get()
  end

  # Test Ack Conn No Ack Reget:
  # * Send a messsage
  # * Subscribe with ack, and receive
  # * Never send an ACK
  # * Reconnect and subscribe with ack => auto
  # * Re-receive the same message
  # Expectation: no client errors, and no server crashes.
  def test_0020_ack_conn_no_ack_reget
    received = no_ack_get()
    #
    disconnect_conn()
    #
    sleep @reconnect_stagger  # Let server clean up
    open_conn()
    received_02 = get_again("auto")
    #
    assert_equal(received.body, received_02.body, "message content should be the same")
    # And so should the message ID.
    assert_equal(received.headers["message-id"],received_02.headers["message-id"],
      "message ID should be the same")  
    #
  end

  # Test Ack No Ack Reget:
  # * Send a messsage
  # * Subscribe with ack, and receive
  # * Never send an ACK
  # * Reconnect and subscribe with ack => client
  # * Re-receive the same message
  # * Actually ACK the message
  # Expectation: no client errors, and no server crashes.
  def test_0030_ack_conn_no_ack
    received = no_ack_get()
    #
    disconnect_conn()
    #
    sleep @reconnect_stagger  # Let server clean up
    open_conn()
    received_02 = get_again("client")
    #
    assert_equal(received.body, received_02.body, "message content should be the same")
    # And so should the message ID.
    assert_equal(received.headers["message-id"],received_02.headers["message-id"],
      "message ID should be the same")  
    #
  end

  private

  # Send a message, subscribe with "ack" => "client", and receive it.
  # Do *not* send ACK reply.
  def no_ack_get()
    received = nil
    assert_nothing_raised() {
      @conn.send(@queuename, @test_message)
      #
      connection_subscribe(@queuename, { "ack" => "client" })
      received = @conn.receive 
    }
    #
    assert_not_nil(received, "something should be received")
    assert_equal(@test_message, received.body, "received should match sent")
    #
    assert_not_nil(received.headers["message-id"], "message ID should be present")
    #
    received
  end

  # Subscribe and reget a message.  The subscription may or may not be
  # ack => client, depending on the caller.  If ack => client is indicated,
  # the message is actually ACK'd.
  def get_again(ackmode)
    received = nil
    assert_nothing_raised() {
      connection_subscribe(@queuename, { "ack" => ackmode })
      received = @conn.receive 
    }
    #
    assert_not_nil(received, "something should be received")
    assert_equal(@test_message, received.body, "received should again match sent")
    assert_not_nil(received.headers["message-id"], "message ID should be present")
    #
    assert_nothing_raised() {
      @conn.ack(received.headers["message-id"]) if ackmode == "client"
    }
    received
  end

end # of class

