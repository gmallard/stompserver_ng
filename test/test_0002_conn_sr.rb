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
    mtosend = @test_message + "-0010"
    assert_nothing_raised() {
      @conn.send(@queuename, mtosend) 
      connection_subscribe(@queuename)
      received = @conn.receive 
    }
    assert_not_nil(received, "something should be received")
    assert_equal(mtosend, received.body, "received should match sent")
  end

  # Test a single send and receive over different connections.
  def test_0020_send_receive
    received = nil
    mtosend = @test_message + "-0020"
    assert_nothing_raised() {
      @conn.send(@queuename, mtosend)
      sleep 3
    }
    teardown
    setup
    assert_nothing_raised() {
      connection_subscribe(@queuename)
      Timeout::timeout(4) do
        received = @conn.receive 
      end
    }
    assert_not_nil(received, "something should be received 20")
    assert_equal(mtosend, received.body, "received should match sent 20")
  end

  # Test a single send and receive over different connections,
  # issue subscribe before send:
  # stompserver - fail
  # AMQ - fail
  # Note: 'fail' means that the second connection will issue 'receive', and
  # no message will ever be received.
  def test_0030_send_receive
    received = nil
    mtosend = @test_message + "-0030"
    assert_nothing_raised() {
      connection_subscribe(@queuename)  # This
      @conn.send(@queuename, mtosend)
      sleep 4                           # plus this cause fail
      # NOTE!!! - without the above 'sleep':
      # AMQ will sometimes fail, and sometimes succeed.  It seems to 
      # depend on timing, current system load, .....
    }
    teardown
    setup
    assert_nothing_raised() {
      connection_subscribe(@queuename)
    }
    assert_raise(Timeout::Error) {
      Timeout::timeout(4) do
        received = @conn.receive 
      end
    }
  end

end # of class

