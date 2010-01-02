require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0001_Conn < Test_0000_Base

  def setup
    super
  end
  #
  def test_0000_params
    check_parms()
  end
  #
  def test_0010_connect
    open_conn()
    assert_not_nil(@conn, "connection should not be nil")
    sleep @sleep_time if @sleep_time > 0
  end
  #
  def test_0015_disconnect
    disconnect_conn()
    assert_nil(@conn, "connection should be nil after disconnect")
  end
end # of class

