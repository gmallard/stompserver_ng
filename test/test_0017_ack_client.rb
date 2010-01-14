require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test ack => client using a Stomp Client.
#
class Test_0017_Ack_Client < Test_0000_Base

  # Setup.
  # * Queue Name
  # * Message body
  # * Count for multiples
  # * Open a Stomp Client
  def setup
    super
    @queue_name = "/queue/ackclisgl/" + name()
    @test_message = "The Answer is Blowin' in the Wind."
    @times = 10
    open_client()
  end

  # Teardown.
  # * Close the Stomp Client
  def teardown
    close_client()
  end

  # Test ACK from client
  def test_0010_ack_send_receive
    ack_client_test("ack")
  end

  # Test ACK from client with symbol
  def test_0020_ack_send_receive_sym
    ack_client_test(:ack)
  end

  # Test ACK from client with miltiple messages
  def test_0030_ack_send_receive_mult
    ack_client_test("ack", @times)
  end

  # Test ACK from client with symbol and multiple messages
  def test_0040_ack_send_receive_mult_sym
    ack_client_test(:ack, @times)
  end

  private

  def ack_client_test(ackparm = nil, ntimes = 1)
    received = nil
    count = 0
    assert_nothing_raised() {
      ntimes.times do |n|
        @client.send(@queue_name, "#{@test_message} #{n+1}", 
          {"persistent" => true, 
          "client-id" => "ack_client_send_multsr", 
          "reply-to" => @queue_name} )
      end
      @client.subscribe(@queue_name,
        {"persistent" => true, "client-id" => "ack_client_send_multrcv",
         ackparm => "client" } ) do |message|
        received = message
        @client.acknowledge(received)   # ACK the message
        count += 1
      end
      sleep 0.5 until received
    }
    assert_equal(ntimes,count,"counts should match: #{@queue_name}")
  end

end # of class

