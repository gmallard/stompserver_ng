require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0019_Ack_No_Ack < Test_0000_Base

  #
  def setup
    super
    @queue_name = "/queue/acknoack"
    @test_message = "Bad moon risin' ....."
  end

  #
  def teardown
  end

  # test_0010_ack_no_ack
  #
  # Test client and server stability when ack => client is requested, but an
  # acknowledgement is never sent.
  #
  # Expected:
  #
  # * test should pass
  # * server should <b>not</b> crash
  #
  def test_0010_ack_no_ack
    #
    make_client()
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
      sleep 1.0 until received
      #
      sleep @sleep_time if @sleep_time > 0
      # Make sure what was received is the same is what was sent
      assert_equal(@test_message, received.body, "get what ya' give .....")
    }
    # But now, do _not_ ack the message, just close the client connection
    close_client()
    #
  end

end # of class

