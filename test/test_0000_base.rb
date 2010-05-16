require 'rubygems'
require 'stomp'
require 'test/unit'
require 'yaml'
require 'timeout'
#
class Test_0000_Base < Test::Unit::TestCase

  # Base setup.
  # * Load configuration parameters
  # * Initialize connection and client instances.
  # * Override sleep time from environment
  def setup
    @runparms = load_config()
    @conn = nil
    @client = nil
    @sleep_time = ENV['TEST_SLEEP'] ? ENV['TEST_SLEEP'].to_f : 0.0
  end # of setup

  # Default test for the base class.  Will always pass.
  # Required by the test framework.
  def test_0000_default
    assert(true)
  end

  private

  # Load yaml configuration file
  def load_config()
    yfname = File.join(File.dirname(__FILE__), "props.yaml")
    parms = YAML.load(File.open(yfname))
    # Allow override of:
    # * host
    # * port
    # * user name
    # * user password
    # from the environment.
    parms[:host] = ENV['STOMP_HOST'] if ENV['STOMP_HOST']
    parms[:port] = ENV['STOMP_PORT'] if ENV['STOMP_PORT']
    parms[:userid] = ENV['STOMP_USER'] if ENV['STOMP_USER']
    parms[:password] = ENV['STOMP_PASS'] if ENV['STOMP_PASS']
    parms
  end

  protected

  # Sanity check that required parms are present
  def check_parms()
    assert_not_nil(@runparms[:userid],"userid must be present")
    assert_not_nil(@runparms[:password],"password must be present")
    assert_not_nil(@runparms[:host],"host must be present")
    assert_not_nil(@runparms[:port],"port must be present")
  end

  # Open a Stomp Connection
  def open_conn()
    assert_nothing_raised() {
      @conn = Stomp::Connection.open(@runparms[:userid],
        @runparms[:password], 
        @runparms[:host], 
        @runparms[:port])
    }
  end

  # Disconnect a Stomp Connection
  def disconnect_conn()
    if @conn
      assert_nothing_raised() {
        @conn.disconnect
      }
    end
    @conn = nil
  end

  # Open a Stomp Client
  def open_client()
    assert_nothing_raised() {
      @client = Stomp::Client.open(@runparms[:userid],
        @runparms[:password], 
        @runparms[:host], 
        @runparms[:port])
    }
  end

  # Close a Stomp Client
  def close_client()
    assert_nothing_raised() {
      @client.close if @client
    }
    @client = nil
  end

  # Convenience method for subscribing to a destination given a
  # Stomp Connection.
  def connection_subscribe(qname, headers = {}, subId = nil)
    @conn.subscribe(qname, headers, subId)
  end

end # of class

