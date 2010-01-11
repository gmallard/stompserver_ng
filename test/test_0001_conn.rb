require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Basic connection tests.
#
class Test_0001_Conn < Test_0000_Base

  #
  def setup
    super
    @times = 10
  end

  # Sanity check parameters
  def test_0000_params
    check_parms()
  end

  # Single connect
  def test_0010_connect
    open_conn()
    assert_not_nil(@conn, "connection should not be nil")
    sleep @sleep_time if @sleep_time > 0
  end

  # Single disconnect
  def test_0015_disconnect
    disconnect_conn()
    assert_nil(@conn, "connection should be nil after disconnect")
  end

  # Show that multiple connect/disconnect sequences in a row can be issued.
  def test_0020_connect_disc_mult
    @times.times do |n|
      open_conn()
      assert_not_nil(@conn, "connection should not be nil, try #{n}")
      disconnect_conn()
      assert_nil(@conn, "connection should be nil after disconnect, try #{n}")
    end
  end

end # of class

