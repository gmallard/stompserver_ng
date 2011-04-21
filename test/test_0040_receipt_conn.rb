require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test the most basic use of receipts.
#
class Test_0040_Receipt_Conn < Test_0000_Base

  # Setup.
  # * Queue name
  # * Message
  # * Receipt ID
  # * RECEIPT Command
  def setup
    super
    @queuename = "/queue/receipt/" + name()
    @test_message = "Abracadabra!"
    @receipt_id = "zztop-" + name()
    @recpt_command = "RECEIPT"
    @msg_command = "MESSAGE"
  end
  
  # Teardown.
  def teardown
  end

  # Send Get Receipt.
  # * Put a message on a queue
  # * Disconnect and reconnect
  # * Subscribe with receipt requested
  # * Receive the message and the receipt
  # * Insure all received information is correct
  #
  # Note: Some servers can vary the order in which the RECEIPT frame and 
  # MESSAGE frame are emitted.  ActiveMQ e.g. exhibits this behavior.
  #
  # Sometimes:
  #
  # * RECEIPT frame is first
  # * MESSAGE frame is second
  #
  # and other times the order is reversed.
  #
  # Further, this behavior is in line with the stomp specification, which
  # does not indicate _when_ a receipt will be sent:  only that it _will_ 
  # be sent.
  #
  def test_0010_send_get_receipt
    # Put something on the queue
    open_conn()
    assert_nothing_raised() {
      @conn.publish(@queuename, @test_message) 
    }
    disconnect_conn()
    # Now get it with a receipt requested.
    open_conn()
    msg_01 = msg_02 = nil
    assert_nothing_raised() {
      connection_subscribe(@queuename, "receipt" => @receipt_id)
      msg_01 = @conn.receive 
      msg_02 = @conn.receive 
    }
    disconnect_conn()
    #
    assert_not_nil(msg_01, "message 1 should be present")
    assert_not_nil(msg_02, "message 2 should be present")
    #
    recpt = msg = nil
    case msg_01.command
      when @recpt_command
        recpt, msg = msg_01, msg_02
      when @msg_command
        msg, recpt = msg_01, msg_02
      else
        fail "Invalid frame: #{msg_01.command}" 
    end
    #
    assert_equal(@receipt_id, recpt.headers['receipt-id'], 
      "receipt ID should match")
    assert_equal(recpt.body, '', "receipt body should be empty")
    assert_equal(@test_message, msg.body, "receive should be what is sent")
  end
end # of class

