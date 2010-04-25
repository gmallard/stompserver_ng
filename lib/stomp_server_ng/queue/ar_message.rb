gem 'activerecord'
require 'active_record'
require 'stomp_server/queue/ar_reconnect'

class ArMessage < ActiveRecord::Base
  serialize :frame
end
