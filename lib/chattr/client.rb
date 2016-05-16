require 'websocket-eventmachine-client'
require 'json'

module Chattr
  class Client
    def initialize(host, port, user_name)
      @host = host
      @port = port
      @user_name = user_name
      #might persist this in some kind of database for the client, but this is really only a stub for the server specs
      @received_messages = []
    end

    def connect
      EM.run do
        puts "#{@user_name} connecting to: #{@host}:#{@port}"
        @ws = WebSocket::EventMachine::Client.connect(:uri => "ws://#{@host}:#{@port}/?user_name=#{@user_name}")

        @ws.onopen do
          puts "Client #{@user_name}: Connected to server"
        end

        @ws.onmessage do |msg, type|
          return if type == :binary #binary is unsupported

          msg_array = JSON.parse(msg)

          puts "Client #{@user_name}: Received message(s):"
          puts msg_array

          @received_messages.concat(msg_array)
        end

        @ws.onclose do |code, reason|
          puts "Client #{@user_name}: Disconnected with status code: #{code}, #{reason}"
        end
      end
    end

    #In the real world, a client might be required to look up recipient id in some kind of external directory service and pass it as a param. For the purposes of this exercise, we just use user_name
    def send_message(recipient_user_name, msg)
      raise RuntimeError.new("Attempt to send message but not connected") if @ws.nil?

      @ws.send({request: "message", recipient_user_name: recipient_user_name, msg: msg}.to_json)
    end

    #client is responsible for reporting when it last had a connection with the server, because different devices may have different last connection times
    #timestamp is in epoch utc
    def request_history(timestamp=1.day.ago)
      @ws.send({request: "history", timestamp: timestamp}.to_json)
    end

    def received_message_count
      @received_messages.count
    end

    def disconnect
      @ws.close
    end
  end
end