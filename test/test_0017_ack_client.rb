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
    ack_client_test(:ackparm => "ack", :times => 1, :mod => "0010")
  end

  # Test ACK from client with symbol
  def test_0020_ack_send_receive_sym
    ack_client_test(:ackparm => :ack, :times => 1, :mod => "0020")
  end

  # Test ACK from client with miltiple messages
  def test_0030_ack_send_receive_mult
    ack_client_test(:ackparm => "ack", :times => @times, :mod => "0030")
  end

  # Test ACK from client with symbol and multiple messages
  def test_0040_ack_send_receive_mult_sym
    ack_client_test(:ackparm => :ack, :times => @times, :mod => "0040")
  end

  private

  def ack_client_test(params = {})
    received = nil
    count = 0
    assert_nothing_raised() {
      params[:times].times do |n|
        @client.publish(@queue_name, "#{@test_message} #{n+1}", 
          {"persistent" => true, 
          "client-id" => "0017_putr_#{params[:mod]}", 
          "reply-to" => @queue_name} )
      end
      @client.subscribe(@queue_name,
        {"persistent" => true, 
          "client-id" => "0017_getr_#{params[:mod]}",
          params[:ackparm] => "client" } 
          ) do |message|
        received = message
        @client.acknowledge(received)   # ACK the message
        count += 1
      end
      sleep 2.0 until received
    }
    assert_equal(params[:times],count,"counts should match: #{@queue_name}")
  end

end # of class

