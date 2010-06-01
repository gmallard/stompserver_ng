require 'rubygems' if RUBY_VERSION =~ /1.8/
require 'active_record'
#
# = cre_sqlite3 - create an sqlite3 data base for use by stompserver_ng
#
# For now, the db parameters are hard coded.  Change as required.
# Note: directory structure should already exist.
#
db_params = {
  'adapter' => 'sqlite3',
  'database' => "/tmp/stompserver/etc/stompserver_development"
}
#
# Connect.
#
ActiveRecord::Base.establish_connection(db_params)
puts "sqlite3 Connection complete."
#
# Define the ar_messages table.
#
ActiveRecord::Schema.define do
  create_table 'ar_messages' do |t|
    t.column 'stomp_id', :string, :null => false
    t.column 'frame', :text, :null => false
  end
end
puts "sqlite3 table create complete."

