MAGIC_WORD = "tacos"

module Bot
  def self.handle_message(ws : HTTP::WebSocket, received_message : JSON::Any)
    puts "\n\nMESSAGE #{received_message}"

    return if received_message["type"]? == "ping"

    if message = received_message["message"]?
      channel_id = message["channelId"].as_s

      if message["type"].as_s == "new_message"
        if message["text"].as_s.downcase == "hello bot"
          response = {
            command: "message",
            identifier: GATEWAY_IDENTIFIER,
            data: {
              action: "send_message",
              text: "Hello, @#{message.dig("author", "username")}!",
              channelId: channel_id
            }.to_json
          }.to_json
          ws.send(response)
        end
        if message["text"].as_s.matches?(/#{MAGIC_WORD}/)
          response = {
            command: "message",
            identifier: GATEWAY_IDENTIFIER,
            data: {
              action: "send_message",
              text: "You said #{message.dig("streamer", "username")}'s magic word!",
              channelId: channel_id
            }.to_json
          }.to_json
          ws.send(response)
        end
      end
    end
  end
end
