require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0001_Conn_Mult < Test_0000_Base
  #
  def setup
    super
    @times = 10
  end
  #
  def teardown
  end
  # Show that multiple connect/disconnect sequences in a row can be issued.
  def test_0010_connect_disc_mult
    @times.times do |n|
      open_conn()
      assert_not_nil(@conn, "connection should not be nil, try #{n}")
      disconnect_conn()
      assert_nil(@conn, "connection should be nil after disconnect, try #{n}")
    end
  end
  #
end # of class

