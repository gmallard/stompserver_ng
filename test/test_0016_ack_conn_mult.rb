require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0015_Ack_Conn < Test_0000_Base

  def setup
    super
    open_conn()
    @queuename = "/queue/mult_connack"
    @test_message = "Stir it up ...."
    #
    @times = 10
  end

  #
  def teardown
    disconnect_conn()
  end

  # Test ACK of multiple messages
  def test_0020_ack_conn_mult
    #
    received = nil
    assert_nothing_raised() {
      @times.times do |n|
        @conn.send(@queuename, "#{@test_message} #{n+1}")
      end
    }
    #
    subscribe(@queuename, { "ack" => "client" })
    #
    assert_nothing_raised() {
      @times.times do |n| 
        received = @conn.receive 
        @conn.ack(received.headers["message-id"]) 
      end
    }
    #
  end

  # Make sure that connect still works.
  def test_0099_ack_conn_last
    assert_not_nil(@conn, "connection should not be nil")
  end

end # of class

