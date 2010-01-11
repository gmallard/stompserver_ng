require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test a basic send and receive over a Stomp Connection.
#
class Test_0002_Conn_SR < Test_0000_Base

  # Setup.
  # * Open the connection
  # * Generate queue name for this test
  # * Specify the message
  def setup
    super
    open_conn()
    @queuename = "/queue/connsr/" + name()
    @test_message = "Abracadabra!"
  end

  # Teardown.
  # * Disconnect
  def teardown
    disconnect_conn()
  end

  # Test a single send and receive over the same connection.
  def test_0010_send_receive
    received = nil
    assert_nothing_raised() {
      @conn.send(@queuename, @test_message) 
      connection_subscribe(@queuename)
      received = @conn.receive 
    }
    assert_not_nil(received, "something should be received")
    assert_equal(@test_message, received.body, "received should match sent")
  end

end # of class

