require 'rubygems' if RUBY_VERSION =~ /1.8/
require 'active_record'
#
# = cre_mysql - create a mysql data base for use by stompserver_ng
#
# For now, the db parameters are hard coded.  Change as required.
#
db_params = {
  'adapter' =>  'mysql',
  'encoding' =>  'utf8',
  'database' =>  'ssng_dev',
  'pool' => 5,
  'username' => 'ssng',
  'password' => 'xxxxxxxx',
  'host' => 'localhost',
  'port' => 3306

}
#
# Connect.
#
ActiveRecord::Base.establish_connection(db_params)
puts "mysql Connection complete."
#
# Define the ar_messages table.
#
ActiveRecord::Schema.define do
  create_table 'ar_messages' do |t|
    t.column 'stomp_id', :string, :null => false
    t.column 'frame', :text, :null => false
  end
end
puts "mysql table create complete."

