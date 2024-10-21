require 'socket'
require 'json'
require 'logger'
require 'mongo'

#ROS操作クラス
class Robot
  def initialize(host, port)
    @host = host
    @port = port
    @socket = nil
    @logger = Logger.new(STDOUT)
  end

  def connect
    if @socket==nil
      @socket = TCPSocket.open(@host, @port)
      @logger.info("Connected to Robot:#{@host} on port #{@port}")
    else
      @logger.warn("Socket is not connected")
    end
  end

  def disconnect
    if @socket
      @socket.close
      @logger.info("Disconnected from Robot:#{@host} on port #{@port}")
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
      #@socket.puts(JSON.generate(subscribe_message))
      data = @socket.readpartial(1023)
      message = JSON.parse(data)
      #puts "Subscribed to topic: #{message}"
      #puts "Subscribed to topic: #{data}"
      
      @logger.info("> rec_data #{message}")
    else
      @logger.warn("Socket is not connected")
    end
  end

  def list_topics
    data=service('/rosapi/topics')
    # topicsを抽出
    topics = data["values"]["topics"]

    # 結果を表示
    puts "Extracted topics:"
    topics.each { |topic| @logger.info("active topic #{topic}") }
    return topics
  end

def service(service_name)
  service_request = {
    op: "call_service",
    service: service_name,
    id: "call_service_#{rand(1000)}",
    args: {}
  }

  # JSONメッセージを送信
  @socket.puts(service_request.to_json)

  # 応答を受け取る
  data = ""
  buffer_size = 1023

  begin
    loop do
      # 1023バイトずつ読み取る
      chunk = @socket.readpartial(buffer_size)
      data << chunk

      # 特定の終了条件、例えば JSON のメッセージが完全に取得されたかを確認
      # JSONの応答が配列やオブジェクトであることを前提に、パースが成功するまで読み続ける
      break if chunk.size < buffer_size || (data.start_with?('{') && data.end_with?('}')) || (data.start_with?('[') && data.end_with?(']'))
    end
  rescue EOFError
    @logger.error("End of stream.")
  end

  # データが完全に受け取れたらパース
  begin
    message = JSON.parse(data)
    @logger.info("> rec_service #{message}")
    return message
  rescue JSON::ParserError => e
    @logger.error("Failed to parse JSON: #{e.message}")
    return nil
  end
end

# トピックが存在するかを判定する関数
def topic_exists?(topics, topic_name)
  topics.include?(topic_name)
end

def send_msg(topic_name,message,n)
  if @socket
      exists = topic_exists?(list_topics, topic_name)
      if exists
          #送信するデータ(JSON)
          publish_msg = {
              op: 'publish',
              topic: topic_name,
              msg: message
          }
          #@socket.puts(JSON.generate(publish_msg))

          i=0
          while i<n do
            @socket.puts(JSON.generate(publish_msg))
            @logger.info("Message sent: #{publish_msg}")
            i+=1
            sleep(0.1)
          end
        else
          @logger.warn("#{topic_name} is not active topic")
        end
        
    else
      @logger.warn("Socket is not connected")
    end
  end
end