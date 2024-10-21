require 'socket'
require 'json'
require 'logger'
require 'mongo'

# ROS操作クラス
class Robot
  def initialize(host, port)
    @host = host
    @port = port
    @socket = nil
    @logger = Logger.new(STDOUT)
  end

  def connect
    if @socket.nil?
      @socket = TCPSocket.open(@host, @port)
      @logger.info("Connected to Robot: #{@host} on port #{@port}")
    else
      @logger.warn("Socket is already connected")
    end
  end

  def disconnect
    if @socket
      @socket.close
      @logger.info("Disconnected from Robot: #{@host} on port #{@port}")
    else
      @logger.warn("Socket is not connected")
    end
  end

  def receive_msg(topic_name)
    if @socket
      subscribe_message = {
        op: 'subscribe',
        topic: topic_name 
      }.to_json
      @socket.write(subscribe_message + "\n")
      data = @socket.readpartial(1023)
      message = JSON.parse(data)
      @logger.info("> rec_data #{message}")
    else
      @logger.warn("Socket is not connected")
    end
  end

  def service(service_name)
    service_request = {
      op: "call_service",
      service: service_name,
      id: "call_service_#{rand(1000)}",
      args: {}
    }
    @socket.puts(service_request.to_json)

    data = ""
    buffer_size = 1023

    begin
      loop do
        chunk = @socket.readpartial(buffer_size)
        data << chunk
        break if chunk.size < buffer_size || (data.start_with?('{') && data.end_with?('}')) || (data.start_with?('[') && data.end_with?(']'))
      end
    rescue EOFError
      @logger.error("End of stream.")
    end

    begin
      message = JSON.parse(data)
      @logger.info("> rec_service #{message}")
      return message
    rescue JSON::ParserError => e
      @logger.error("Failed to parse JSON: #{e.message}")
      return nil
    end
  end

  def list_topics
    data = service('/rosapi/topics')
    topics = data["values"]["topics"]
    topics.each { |topic| @logger.info("active topic #{topic}") }
    return topics
  end

  def topic_exists?(topics, topic_name)
    topics.include?(topic_name)
  end

  def send_msg(topic_name, message, n)
    if @socket
      exists = topic_exists?(list_topics, topic_name)
      if exists
        publish_msg = {
          op: 'publish',
          topic: topic_name,
          msg: message
        }
        i = 0
        while i < n do
          @socket.puts(JSON.generate(publish_msg))
          @logger.info("Message sent: #{publish_msg}")
          i += 1
          sleep(0.1)
        end
      else
        @logger.warn("#{topic_name} is not an active topic")
      end
    else
      @logger.warn("Socket is not connected")
    end
  end
end