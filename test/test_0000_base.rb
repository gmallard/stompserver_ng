require 'rubygems'
require 'stomp'
require 'test/unit'
require 'yaml'
#
# $:.unshift File.dirname(__FILE__)
#
class Test_0000_Base < Test::Unit::TestCase

  def setup
    @runparms = load_config()
    @conn = nil
    @client = nil
  end # of setup

  #
  def test_0000_default
    assert(true)
  end

  private
  #
  def load_config()
    yfname = File.join(File.dirname(__FILE__), "props.yaml")
    parms = YAML.load(File.open(yfname))
    parms
  end

  protected
  #
  def check_parms()
    assert_not_nil(@runparms[:userid],"userid should not be nil")
    assert_not_nil(@runparms[:password],"userid should not be nil")
    assert_not_nil(@runparms[:host],"userid should not be nil")
    assert_not_nil(@runparms[:port],"userid should not be nil")
  end
  #
  def open_conn()
    assert_nothing_raised() {
      @conn = Stomp::Connection.open(@runparms[:userid],
        @runparms[:password], 
        @runparms[:host], 
        @runparms[:port])
    }
  end
  #
  def disconnect_conn()
    if @conn
      assert_nothing_raised() {
        @conn.disconnect
      }
    end
    @conn = nil
  end
  #
  def make_client()
    assert_nothing_raised() {
      @client = Stomp::Client.open(@runparms[:userid],
        @runparms[:password], 
        @runparms[:host], 
        @runparms[:port])
    }
  end
  #
  def close_client()
    assert_nothing_raised() {
      @client.close if @client
    }
    @client = nil
  end
  #
  def subscribe(qname, headers = {})
    @conn.subscribe(qname, headers)
  end

end # of class

