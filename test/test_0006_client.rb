require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
# Test client open and close sequences.
#
class Test_0006_Client < Test_0000_Base

  # Setup
  # * Define number of loops for multiple tests.
  def setup
    super
    @times = 10
  end

  # Teardown.
  def teardown
  end

  # Single client open then close.
  def test_0010_open_then_close
    open_client()
    assert_not_nil(@client, "client should not be nil")
    close_client()
    assert_nil(@client, "client should be nil after close")
  end

  # Multiple client open/close sequences.
  def test_0020_open_then_close_mult
    @times.times do |n|
      open_client()
      assert_not_nil(@client, "client should not be nil, try #{n}")
      close_client()
      assert_nil(@client, "client should be nil after close, try #{n}")
    end
  end
end # of class

