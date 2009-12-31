require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0018_Ack_Client_Mult < Test_0000_Base

  #
  def setup
    super
    @queue_name = "/queue/ackclimult"
    @test_message = "Like a castle in his fortress in a medieval game .... "
    make_client()
    @times = 10
  end

  #
  def teardown
    close_client()
  end

  #
  def test_0010_ack_send_receive_mult
    received = nil
    assert_nothing_raised() {
      @times.times do |n|
        @client.send(@queue_name, "#{@test_message} #{n+1}", 
          {"persistent" => true, 
          "client-id" => "ack_client_send_multsr", 
          "reply-to" => @queue_name} )
      end
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "ack_client_send_multrcv",
         "ack" => "client" } ) do |message|
        received = message
        @client.acknowledge(received)   # ACK the message
      end
      sleep 1.0 until received
    }
  end

  #
  def test_0099_test_client
    assert_not_nil(@client, "client should not be nil")
  end

end # of class

