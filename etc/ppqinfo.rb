require 'pp'
#
# Pretty print the queue information file.
#
# Sample Use:
#
# ruby etc/ppqinfo.rb /ad3/tmp/stompserver/.queue/qinfo 
#
qfile = ARGV[0]
qinfo = nil
File.open(qfile) do |f|
  qinfo = Marshal.load(f)
end
pp qinfo

