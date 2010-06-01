require 'rubygems' if RUBY_VERSION =~ /1.8/
require 'active_record'
#
# = cre_postgres - create a postgres data base for use by stompserver_ng
#
# For now, the db parameters are hard coded.  Change as required.
#
db_params = {
  'adapter' =>  'postgresql',
  'encoding' =>  'utf8',
  'database' =>  'ssng_dev',
  'pool' => 5,
  'username' => 'ssng',
  'password' => 'xxxxxxxx',
  'host' => 'localhost',
  'port' => 5432
}
#
# Connect.
#
ActiveRecord::Base.establish_connection(db_params)
puts "postgres Connection complete."
#
# Define the ar_messages table.
#
ActiveRecord::Schema.define do
  create_table 'ar_messages' do |t|
    t.column 'stomp_id', :string, :null => false
    t.column 'frame', :text, :null => false
  end
end
puts "postgres table create complete."

