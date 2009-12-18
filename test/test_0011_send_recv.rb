require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0011_Send_Recv < Test_0000_Base

  #
  def setup
    super
    @queue_name = "/queue/sendrecv"
    @test_message = "This is a test message."
    make_client()
  end

  #
  def teardown
    close_client()
  end

  #
  def test_0010_send
    assert_nothing_raised() {
       @client.send(@queue_name, @test_message, 
         {"persistent" => true, 
         "client-id" => "SRSClient", 
         "reply-to" => @queue_name} )
    }
  end

  #
  def test_0015_recv
    assert_nothing_raised() {
      received = nil
      @client.subscribe(@queue_name,
       {"persistent" => true, "client-id" => "SRRClient"} ) do |message|
        received = message
      end
      sleep 0.1 until received
      assert_equal(@test_message, received.body, "what is sent should be received")
    }
  end

end # of class

