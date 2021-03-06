#
#
#
module StompServer
  #
  # Low level physical queue handler.
  #
  class FileQueue < Queue

    # Remove queue directory if it exists.
    def _close_queue(dest)
      Dir.delete(@queues[dest][:queue_dir]) if File.directory?(@queues[dest][:queue_dir])
    end

    # Create queue directory if it does not alrady exist.
    def _open_queue(dest)
      # handle clashes between _ and /
      queue_name = dest.gsub('_','__')
      queue_name = dest.gsub('/','_')
      queue_dir = @directory + '/' + queue_name
      @queues[dest][:queue_dir] = queue_dir
      Dir.mkdir(queue_dir) unless File.directory?(queue_dir)
    end

    # Write a messaage frame to the file system.
    def _writeframe(dest,frame_todump,msgid)
      filename = "#{@queues[dest][:queue_dir]}/#{msgid}"
      frame = frame_todump.dup
      frame_body = frame.body
      frame.body = ''
      frame_image = Marshal.dump(frame)
      framelen = sprintf("%08x", frame_image.length)
      bodylen = sprintf("%08x", frame_body.length)
      File.open(filename,'wb') {|f| f.syswrite("#{framelen}#{bodylen}#{frame_image}#{frame_body}")}
      return true
    end

    # Read a message frame from the file system.
    def _readframe(dest,msgid)
      filename = "#{@queues[dest][:queue_dir]}/#{msgid}"
      file = nil
      File.open(filename,'rb') {|f| file = f.read}
      frame_len = file[0,8].hex
      body_len = file[8,8].hex
      frame = Marshal::load(file[16,frame_len])
      frame.body = file[(frame_len + 16),body_len]
      if File.delete(filename)
        result = frame
      else
        result = false
      end
      return result
    end
  end # of class
end # of module

