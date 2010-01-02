require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0020_Ack_Ns_Reget_Ack < Test_0000_Base

  #
  def setup
    super
    @queue_name = "/queue/acknaregeta"
    @test_message = "Tangled Up In Blue ....."
    @reconnect_stagger = 1
  end

  #
  def teardown
  end

  # test_0010_ack_no_ack_reget
  #
  #
  def test_0010_ack_no_ack_reget
    #
    make_client()
    sleep @sleep_time if @sleep_time > 0
    #
    received = nil
    assert_nothing_raised() {
      # Send a single message to a queue
      @client.send(@queue_name, @test_message, 
        {"persistent" => true, 
          "client-id" => "anareg_client_put", 
          "reply-to" => @queue_name} )
      sleep @sleep_time if @sleep_time > 0
      # Subscribe with "ack" => "client", and receive the message
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "anareg_client_get",
          "ack" => "client" } ) do |message|
        received = message
      end
      sleep 1.0 until received
      #
      sleep @sleep_time if @sleep_time > 0
      # Make sure what was received is the same is what was sent
      assert_equal(@test_message, received.body, "get what ya' give .....")
    }
    # But now, do _not_ ack the message, just close the client connection
    close_client()
    #
    # The re-connect and re-get sequence
    #
    sleep @sleep_time if @sleep_time > 0
    sleep @reconnect_stagger  # Server needs to asynchronously complete disconnect
    make_client()
    sleep @sleep_time if @sleep_time > 0
    #
    received_02 = nil
    assert_nothing_raised() {
      # Subscribe with no ack specified, and receive the message
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "anareg_client_reget",
         "ack" => "client" } ) do |message|
        received_02 = message
      end
      sleep 1.0 until received_02
      #
      sleep @sleep_time if @sleep_time > 0
      # Make sure what was received is the same is what was sent
      assert_equal(@test_message, received_02.body, "get again what ya' gave .....")
      #
      @client.acknowledge(received_02)   # ACK the message this time
    }
    #
    close_client()
  end

end # of class

