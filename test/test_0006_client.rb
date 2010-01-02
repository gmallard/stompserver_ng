require 'rubygems'
require 'stomp'
#
require 'test/unit'
$:.unshift File.dirname(__FILE__)
require 'test_0000_base'
#
class Test_0006_Client < Test_0000_Base

  def setup
    super
    @times = 10
  end
  #
  def teardown
    #
  end
  #
  def test_0010_make_client
    make_client()
    assert_not_nil(@client, "client should not be nil")
  end
  #
  def test_0015_close_client
    close_client()
    assert_nil(@client, "client should be nil after close")
  end
  #
  def test_0020_make_then_close
    make_client()
    assert_not_nil(@client, "client should not be nil")
    close_client()
    assert_nil(@client, "client should be nil after close")
  end
  #
  def test_0020_make_then_close_mult
    @times.times do |n|
      make_client()
      assert_not_nil(@client, "client should not be nil, try #{n}")
      close_client()
      assert_nil(@client, "client should be nil after close, try #{n}")
    end
  end
end # of class

