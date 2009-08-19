require 'active_record'

# Added reconnection patch
# http://snipplr.com/view.php?codeview&id=4195
module ActiveRecord::ConnectionAdapters
  class MysqlAdapter
    alias :orig_execute :execute 
    def execute(sql,name=nil)
      orig_execute(sql,name)
      rescue ActiveRecord::StatementInvalid => exception
        if LOST_CONNECTION_ERROR_MESSAGES.any? { |msg| exception.message. =~ /#{msg}/ } 
          reconnect!
          retry
        else
          raise
        end
    end
  end
end

class ArMessage < ActiveRecord::Base
  serialize :frame
end
