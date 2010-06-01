gem 'activerecord'
require 'active_record'
require 'stomp_server_ng/queue/ar_reconnect'
#
#
#
class Logger
  private
  # Rails overrides this method so that it can customize the format
  # of it's logs.  A consequence it that the date, time, etc. disappear
  # from log output.  This little hack overrides the override :-).
  def format_message(*args)
    old_format_message(*args)
  end
end
#
#
#
class ArMessage < ActiveRecord::Base
  serialize :frame
end
