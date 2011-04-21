require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Basic connection tests.
#
class Test_0030_Subscr_Id < Test_0000_Base

  # Setup
  def setup
    super
    open_conn()
  end

  # Teardown
  def teardown
    disconnect_conn()
  end

  # Sanity check parameters
  def test_0000_params
    check_parms()
  end


  # Make sure we get 'subscription' header back from the server
  def test_0010_subscribe_with_id
    qname = "/queue/subscr/id/a.b"
    send_message = "Subscribe with ID check message"
    sub_id = "id-0010"
    @conn.publish(qname,send_message)
    @conn.subscribe(qname, {'id' => 'id-0010'})
    #
    rec_message = @conn.receive
    assert_not_nil rec_message
    assert_not_nil rec_message.headers['subscription']
    assert_equal sub_id, rec_message.headers['subscription']
  end

end # of class

