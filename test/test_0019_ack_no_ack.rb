require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test situations with a Stomp Client where ack mode is specified on a 
# subscribe, but the message is initially never actually ACK'd.
#
class Test_0019_Ack_No_Ack < Test_0000_Base

  # Setup.
  # * Queue name
  # * Message body
  # * Connect stagger/reconnect wait time
  def setup
    super
    @queue_name = "/queue/acknoack/" + name()
    @test_message = "Bad moon risin' ....."
    @reconnect_stagger = 0.5
  end

  # Teardown.
  def teardown
  end

  # Test Ack No Ack Reget:
  # * Send a messsage
  # * Subscribe with ack, and receive
  # * Never send an ACK
  # * Reconnect and subscribe with ack => auto
  # * Re-receive the same message
  # Expectation: no client errors, and no server crashes.
  def test_0020_ack_no_ack_reget
    #
    open_client()
    #
    received = no_ack_get()
    # But now, do _not_ ack the message, just close the client connection
    close_client()
    #
    # The re-connect and re-get sequence
    #
    sleep @reconnect_stagger  # Server needs to asynchronously complete disconnect
    open_client()
    #
    received_02 = get_again("auto")
    #
    assert_equal(received.body, received_02.body, "message content should be the same")
    # And so should the message ID.
    assert_equal(received.headers["message-id"],received_02.headers["message-id"],
      "message ID should be the same")  
    #
    close_client()
  end

  # Test Ack No Ack Reget:
  # * Send a messsage
  # * Subscribe with ack, and receive
  # * Never send an ACK
  # * Reconnect and subscribe with ack => client
  # * Re-receive the same message
  # * Actually ACK the message
  # Expectation: no client errors, and no server crashes.
  def test_0030_ack_no_ack_reget
    #
    open_client()
    #
    received = no_ack_get()
    # But now, do _not_ ack the message, just close the client connection
    close_client()
    #
    # The re-connect and re-get sequence
    #
    sleep @reconnect_stagger  # Server needs to asynchronously complete disconnect
    open_client()
    #
    received_02 = get_again("client")
    #
    assert_equal(received.body, received_02.body, "message content should be the same")
    # And so should the message ID.
    assert_equal(received.headers["message-id"],received_02.headers["message-id"],
      "message ID should be the same")  
    #
    close_client()
  end

  private

  # Send a message, subscribe with "ack" => "client", and receive it.
  # Do *not* send ACK reply.
  def no_ack_get()
    sleep @sleep_time if @sleep_time > 0
    #
    received = nil
    assert_nothing_raised() {
      # Send a single message to a queue
      @client.send(@queue_name, @test_message, 
        {"persistent" => true, 
          "client-id" => "ana_client_put", 
          "reply-to" => @queue_name} )
      sleep @sleep_time if @sleep_time > 0
      # Subscribe with "ack" => "client", and receive the message
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "ana_client_get",
          "ack" => "client" } ) do |message|
        received = message
      end
      sleep 0.5 until received
      #
      sleep @sleep_time if @sleep_time > 0
      # Make sure what was received is the same is what was sent
      assert_equal(@test_message, received.body, "get what ya' give .....")
    }
    received
  end

  # Subscribe and reget a message.  The subscription may or may not be
  # ack => client, depending on the caller.  If ack => client is indicated,
  # the message is actually ACK'd.
  def get_again(ackmode)
    sleep @sleep_time if @sleep_time > 0
    #
    received = nil
    assert_nothing_raised() {
      # Subscribe with ack as specified by caller
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "anareg_client_reget",
         "ack" => ackmode } ) do |message|
        received = message
      end
      sleep 1.0 until received
      #
      sleep @sleep_time if @sleep_time > 0
      # Make sure what was received is the same is what was sent
      assert_equal(@test_message, received.body, "get again what ya' gave .....")
      # Possible ACK, caller decides
      @client.acknowledge(received) if ackmode == "client"
    }
    received
  end

end # of class

