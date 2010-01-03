require 'rubygems'
require 'stomp'
require 'test/unit'
require 'yaml'
#
class Test_0000_Base < Test::Unit::TestCase

  def setup
    @runparms = load_config()
    @conn = nil
    @client = nil
    @sleep_time = ENV['TEST_SLEEP'] ? ENV['TEST_SLEEP'].to_f : 0
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
    # Allow override of host and/or port from the environment.
    parms[:host] = ENV['STOMP_HOST'] if ENV['STOMP_HOST']
    parms[:port] = ENV['STOMP_PORT'] if ENV['STOMP_PORT']
    parms
  end

  protected
  #
  def check_parms()
    assert_not_nil(@runparms[:userid],"userid must be present")
    assert_not_nil(@runparms[:password],"password must be present")
    assert_not_nil(@runparms[:host],"host must be present")
    assert_not_nil(@runparms[:port],"port must be present")
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
  #
end # of class

