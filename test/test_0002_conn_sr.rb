require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0002_Conn_SR < Test_0000_Base

  def setup
    super
    open_conn()
    @queuename = "/queue/connsr"
    @test_message = "Abracadabra!"
  end

  #
  def teardown
    disconnect_conn()
  end

  #
  def test_0010_start
    assert_not_nil(@conn, "connection should not be nil")
  end

  #
  def test_0015_send
    assert_nothing_raised() {
      @conn.send(@queuename, @test_message) 
    }
  end

  #
  def test_0020_receive
    received = nil
    assert_nothing_raised() {
      subscribe(@queuename)
      received = @conn.receive 
    }
    assert_not_nil(received, "something should be received")
    assert_equal(@test_message, received.body, "received should match sent")
  end

end # of class

