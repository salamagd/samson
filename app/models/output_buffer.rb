require 'thread_safe'

# Allows fanning out a stream to multiple listening threads. Each thread will
# have to call `#each`, and will receive each chunk of data that is written
# to the buffer. If a thread starts listening after the buffer has been written
# to, it will receive the previous chunks immediately and then start streaming
# new chunks.
#
# Example:
#
#   buffer = OutputBuffer.new
#
#   listener1 = Thread.new { c = ""; buffer.each {|chunk| c << chunk }; c }
#   listener2 = Thread.new { c = ""; buffer.each {|chunk| c << chunk }; c }
#
#   buffer.write("hello ")
#   buffer.write("world!")
#   buffer.close
#
#   listener1.value #=> "hello world!"
#   listener2.value #=> "hello world!"
#
class OutputBuffer
  # A magic object that signals the end of the stream.
  CLOSE = Object.new

  attr_reader :chunks

  def initialize
    @listeners = ThreadSafe::Array.new
    @chunks = ThreadSafe::Array.new
    @closed = false
  end

  def write(chunk)
    @chunks << chunk unless chunk == CLOSE
    @listeners.each {|listener| listener.push(chunk) }
  end

  def to_s
    chunks.join("\n")
  end

  def close
    @closed = true
    write(CLOSE)
  end

  def each(&block)
    # If the buffer is closed, there's no reason to block the listening
    # thread - just yield all the buffered chunks and return.
    return @chunks.each(&block) if @closed

    queue = Queue.new
    @listeners << queue

    @chunks.each {|chunk| yield chunk }

    while (chunk = queue.pop) && chunk != CLOSE
      yield chunk
    end
  ensure
    @listeners.delete(queue)
  end
end