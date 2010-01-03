require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0040_Receipt_Conn < Test_0000_Base

  def setup
    super
    @queuename = "/queue/test_0040"
    @test_message = "Abracadabra!"
    @receipt_id = "zztop"
    @recv_command = "RECEIPT"
  end
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
    received = nil
    message = nil
    assert_nothing_raised() {
      subscribe(@queuename, "receipt" => @receipt_id)
      received = @conn.receive 
      message = @conn.receive 
    }
    disconnect_conn()
    #
    assert_not_nil(received, "receipt should be received")
    assert_equal(@recv_command, received.command, "command mismatch")
    assert_equal(@receipt_id, received.headers['receipt-id'], "receipt-id should match")
    #
    assert_not_nil(message, "message should be received")
    assert_equal(@test_message, message.body, "get should be what is sent")
  end
end # of class

