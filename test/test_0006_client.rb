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
end # of class

