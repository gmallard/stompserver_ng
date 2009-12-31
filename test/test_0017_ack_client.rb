require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0017_Ack_Client < Test_0000_Base

  #
  def setup
    super
    @queue_name = "/queue/ackclisgl"
    @test_message = "The Answer is Blowin' in the Wind."
    make_client()
  end

  #
  def teardown
    close_client()
  end

  #
  def test_0010_ack_send_receive
    received = nil
    assert_nothing_raised() {
       @client.send(@queue_name, @test_message, 
         {"persistent" => true, 
         "client-id" => "ack_client_send", 
         "reply-to" => @queue_name} )
      @client.subscribe(@queue_name,
       {"persistent" => true, "client-id" => "ack_client_send",
          "ack" => "client" } ) do |message|
        received = message
      end
      sleep 0.5 until received
      assert_equal(@test_message, received.body, "what is sent should be received")
    }
    #
    assert_nothing_raised() {
      @client.acknowledge(received)   # ACK the message
    }
  end

  #
  def test_0099_test_client
    assert_not_nil(@client, "client should not be nil")
  end

end # of class

