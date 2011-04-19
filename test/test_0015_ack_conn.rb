require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test "ack" and :ack on a subscribe to a Stomp Connection.
#
class Test_0015_Ack_Conn < Test_0000_Base

  # Setup.
  # * Open a Stomp Connection
  # * Set the test queue name
  # * Set the message to use.
  # * Set counter for looping tests
  def setup
    super
    open_conn()
    @queuename = "/queue/connack/" + name
    @test_message = "What's up doc?"
    @times = 10
    #
  end

  # Teardown.
  # # Connection disconnect.
  def teardown
    disconnect_conn()
  end

  # Test ACK of a single message
  def test_0010_ack_conn_one
    ack_conn_test("ack")
  end

  # Test ACK of a single message using symbol header
  def test_0020_ack_conn_one_sym
    ack_conn_test(:ack)
  end

  # Test ACK of multiple messages
  def test_0030_ack_conn_mult
    ack_conn_test("ack", @times)
  end

  # Test ACK of multiple messages using symbol header
  def test_0040_ack_conn_mult_sym
    ack_conn_test(:ack, @times)
  end

  private

  def ack_conn_test(ackparm = nil, ntimes = 1)
    #
    received = nil
    assert_nothing_raised() {
      ntimes.times do |n|
        @conn.publish(@queuename, "#{@test_message} #{n+1}")
      end
    }
    #
    connection_subscribe(@queuename, { ackparm => "client" })
    #
    count = 0
    assert_nothing_raised() {
      ntimes.times do |n| 
        received = @conn.receive 
        @conn.ack(received.headers["message-id"]) 
        count += 1
      end
    }
    #
    assert_equal(ntimes,count,"count should be the same: #{@queuename}")
  end

end # of class

