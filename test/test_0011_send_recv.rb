require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test send and receive using a Stomp Client.
#
class Test_0011_Send_Recv < Test_0000_Base

  # Setup
  # * Specify test queue name
  # * Specify message content
  # * Loop count for multiple times tests
  # * Open a Stomp Client
  def setup
    super
    @queue_name = "/queue/sendrecv/" + name()
    @test_message = "This is a test message."
    @times = 10
    open_client()
  end

  # Teardown.
  # * Close the Stomp Client
  def teardown
    close_client()
  end

  # Test single message send and receive.
  def test_0010_send_receive
    assert_nothing_raised() {
      received = nil
      #
      @client.send(@queue_name, @test_message, 
        {"persistent" => true, 
        "client-id" => "0011_sr1send", 
        "reply-to" => @queue_name} )
      #
      @client.subscribe(@queue_name,
       {"persistent" => true, "client-id" => "0011_sr1recv"} ) do |message|
        received = message
      end
      sleep 0.1 until received
      assert_equal(@test_message, received.body, "what is sent should be received")
    }
  end

  # Test send and receive of multiple messages.
  def test_0020_send_mult_receive
    assert_nothing_raised() {
      received = nil
      #
      @times.times do |n|
        @client.send(@queue_name, @test_message + " #{n}", 
          {"persistent" => true, 
          "client-id" => "0011_srXsend", 
          "reply-to" => @queue_name} )
      end
      #
      count = 0
      @client.subscribe(@queue_name,
       {"persistent" => true, "client-id" => "0011_srXrecv"} ) do |message|
        count += 1
        received = message
      end
      sleep 0.25 until received
      assert_equal(@times,count,"0011 counts should match")
    }
  end

end # of class

