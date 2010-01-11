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
    @recv_command = "RECEIPT"
  end
  
  # Teardown.
  def teardown
  end

  # Send Get Receipt.
  # * Put a message on a queue
  # * Disconnect and reconnect
  # * Subscribe with receipt requested
  # * Receive
  # * Insure all receipt information is correct
  #
  def test_0010_send_get_receipt
    # Put something on the queue
    open_conn()
    assert_nothing_raised() {
      @conn.send(@queuename, @test_message) 
    }
    disconnect_conn()
    #
    sleep 1

    # Now get it with a receipt requested.
    open_conn()
    receipt_frame = nil
    message = nil
    assert_nothing_raised() {
      connection_subscribe(@queuename, "receipt" => @receipt_id)
      receipt_frame = @conn.receive 
      message = @conn.receive 
    }
    disconnect_conn()

    #
    assert_not_nil(receipt_frame, "receipt should be present")
    assert_equal(@recv_command, receipt_frame.command, "command mismatch")
    assert_equal(@receipt_id, receipt_frame.headers['receipt-id'], "receipt-id should match")

    #
    assert_not_nil(message, "message should also be present")
    assert_equal(@test_message, message.body, "get should be what is sent")
  end
end # of class

